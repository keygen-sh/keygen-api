# frozen_string_literal: true

module UnionOf
  UNION_PRIMARY_KEY = 'id'.freeze
  UNION_FOREIGN_KEY = 'union_id'.freeze

  class Error < ActiveRecord::ActiveRecordError; end

  class ReadonlyAssociationError < Error
    def initialize(owner, reflection)
      super("Cannot modify association '#{owner.class.name}##{reflection.name}' because it is read-only")
    end
  end

  class ReadonlyAssociationProxy < ActiveRecord::Associations::CollectionProxy
    MUTATION_METHODS = %i[
      insert insert! insert_all insert_all!
      build new create create!
      upsert upsert_all update_all update! update
      delete destroy destroy_all delete_all
    ]

    MUTATION_METHODS.each do |method_name|
      define_method method_name do |*, **|
        raise ReadonlyAssociationError.new(@association.owner, @association.reflection)
      end
    end
  end

  class ReadonlyAssociation < ActiveRecord::Associations::CollectionAssociation
    MUTATION_METHODS = %i[
      writer ids_writer
      insert_record build_record
      destroy_all delete_all delete_records
      update_all concat_records
    ]

    MUTATION_METHODS.each do |method_name|
      define_method method_name do |*, **|
        raise ReadonlyAssociationError.new(owner, reflection)
      end
    end

    def reader
      ensure_klass_exists!

      if stale_target?
        reload
      end

      @proxy ||= ReadonlyAssociationProxy.create(klass, self)
      @proxy.reset_scope
    end
  end

  class Association < ReadonlyAssociation
    def association_scope
      return if
        klass.nil?

      @association_scope ||= Scope.create.scope(self)
    end
  end

  module Preloader
    class Association < ActiveRecord::Associations::Preloader::ThroughAssociation
      def load_records(*)
        preloaded_records # we don't need to load anything except the union associations
      end

      def preloaded_records
        @preloaded_records ||= union_preloaders.flat_map(&:preloaded_records)
      end

      def records_by_owner
        @records_by_owner ||= owners.each_with_object({}) do |owner, result|
          if loaded?(owner)
            result[owner] = target_for(owner)

            next
          end

          records = union_records_by_owner[owner] || []
          records.compact!
          records.sort_by! { preload_index[_1] } unless scope.order_values.empty?
          records.uniq! if scope.distinct_value

          result[owner] = records
        end
      end

      def runnable_loaders
        return [self] if
          data_available?

        union_preloaders.flat_map(&:runnable_loaders)
      end

      def future_classes
        return [] if
          run?

        union_classes  = union_preloaders.flat_map(&:future_classes).uniq
        source_classes = source_reflection.chain.map(&:klass)

        (union_classes + source_classes).uniq
      end

      private

      def data_available?
        owners.all? { loaded?(_1) } || union_preloaders.all?(&:run?)
      end

      def source_reflection = reflection
      def union_reflections = reflection.union_reflections

      def union_preloaders
        @union_preloaders ||= ActiveRecord::Associations::Preloader.new(scope:, records: owners, associations: union_reflections.collect(&:name))
                                                                   .loaders
      end

      def union_records_by_owner
        @union_records_by_owner ||= union_preloaders.map(&:records_by_owner).reduce do |left, right|
          left.merge(right) do |owner, left_records, right_records|
            left_records | right_records # merge record sets
          end
        end
      end

      def build_scope
        scope = source_reflection.klass.unscoped

        if reflection.type && !reflection.through_reflection?
          scope.where!(reflection.type => model.polymorphic_name)
        end

        scope.merge!(reflection_scope) unless reflection_scope.empty_scope?

        if preload_scope && !preload_scope.empty_scope?
          scope.merge!(preload_scope)
        end

        cascade_strict_loading(scope)
      end
    end
  end

  class Scope < ActiveRecord::Associations::AssociationScope
    private

    def last_chain_scope(scope, reflection, owner)
      return super unless reflection.union_of?

      foreign_klass = reflection.klass
      foreign_table = reflection.aliased_table
      primary_key   = reflection.active_record_primary_key

      sources = reflection.union_sources.map do |source|
        association = owner.association(source)

        association.scope.select(association.reflection.active_record_primary_key)
                         .unscope(:order)
                         .arel
      end

      unions = sources.compact.reduce(nil) do |left, right|
        if left
          Arel::Nodes::Union.new(left, right)
        else
          right
        end
      end

      # We can simplify the query if the scope class is the same as our foreign class
      if scope.klass == foreign_klass
        scope.where!(
          foreign_table[primary_key].in(
            foreign_table.project(foreign_table[primary_key])
                         .from(
                           Arel::Nodes::TableAlias.new(unions, foreign_table.name),
                         ),
          ),
        )
      else
        # FIXME(ezekg) Selecting IDs in a separate query is faster than a subquery
        #              selecting IDs, or an EXISTS subquery, or even a
        #              materialized CTE. Not sure why...
        ids = foreign_klass.find_by_sql(
                             foreign_table.project(foreign_table[primary_key])
                                          .from(
                                            Arel::Nodes::TableAlias.new(unions, foreign_table.name),
                                          ),
                           )
                           .pluck(
                             primary_key,
                           )

        scope.where!(
          foreign_table[primary_key].in(ids),
        )
      end

      scope.merge!(
        scope.default_scoped,
      )

      scope
    end

    def next_chain_scope(scope, reflection, next_reflection)
      return super unless reflection.union_of?

      klass         = reflection.klass
      table         = klass.arel_table
      foreign_klass = next_reflection.klass
      foreign_table = foreign_klass.arel_table

      # This holds our union's constraints. For example, if we're unioning across 3
      # tables, then this will hold constraints for all 3 of those tables, so that
      # the join on our target table mirrors the union of all 3 associations.
      foreign_constraints = []

      reflection.union_sources.each do |union_source|
        union_reflection = foreign_klass.reflect_on_association(union_source)

        if union_reflection.through_reflection?
          through_reflection = union_reflection.through_reflection
          through_table      = through_reflection.klass.arel_table

          scope.left_outer_joins!(
            through_reflection.name,
          )

          foreign_constraints << foreign_table[through_reflection.join_foreign_key].eq(through_table[through_reflection.join_primary_key])
        else
          foreign_constraints << foreign_table[union_reflection.join_foreign_key].eq(table[union_reflection.join_primary_key])
        end
      end

      # Flatten union constraints and add any default constraints
      foreign_constraint = unless (where_clause = foreign_klass.default_scoped.where_clause).empty?
                             where_clause.ast.and(foreign_constraints.reduce(&:or))
                           else
                             foreign_constraints.reduce(&:or)
                           end

      scope.joins!(
        Arel::Nodes::InnerJoin.new(
          foreign_table,
          Arel::Nodes::On.new(
            foreign_constraint,
          ),
        ),
      )

      # FIXME(ezekg) Why is this needed? Should be handled automatically...
      scope.merge!(
        scope.default_scoped,
      )

      scope
    end

    # NOTE(ezekg) This overloads our scope's joins to not use an Arel::Nodes::LeadingJoin node.
    def join(table, constraint)
      Arel::Nodes::InnerJoin.new(table, Arel::Nodes::On.new(constraint))
    end
  end

  class Reflection < ActiveRecord::Reflection::AssociationReflection
    attr_reader :union_sources

    def initialize(...)
      super

      @union_sources = @options[:sources]
    end

    def macro             = :union_of
    def union_of?         = true
    def collection?       = true
    def association_class = Association
    def union_reflections = union_sources.collect { active_record.reflect_on_association(_1) }

    def join_scope(table, foreign_table, foreign_klass, alias_tracker = nil)
      predicate_builder = predicate_builder(table)
      scope_chain_items = join_scopes(table, predicate_builder)
      klass_scope       = klass_join_scope(table, predicate_builder)

      # This holds our union's constraints. For example, if we're unioning across 3
      # tables, then this will hold constraints for all 3 of those tables, so that
      # the join on our target table mirrors the union of all 3 associations.
      foreign_constraints = []

      union_sources.each do |union_source|
        union_reflection = foreign_klass.reflect_on_association(union_source)

        if union_reflection.through_reflection?
          source_reflection  = union_reflection.source_reflection
          through_reflection = union_reflection.through_reflection
          through_klass      = through_reflection.klass
          through_table      = through_klass.arel_table

          # Alias table if we're provided with an alias tracker (i.e. via our #join_constraints overload)
          unless alias_tracker.nil?
            through_table = alias_tracker.aliased_table_for(through_table) do
              through_reflection.alias_candidate(union_source)
            end
          end

          # Create base join constraints and add default constraints if available
          through_constraint = through_table[through_reflection.join_primary_key].eq(
            foreign_table[through_reflection.join_foreign_key],
          )

          unless (where_clause = through_klass.default_scoped.where_clause).empty?
            through_constraint = where_clause.ast.and(through_constraint)
          end

          klass_scope.joins!(
            Arel::Nodes::OuterJoin.new(
              through_table,
              Arel::Nodes::On.new(through_constraint),
            ),
          )

          foreign_constraints << table[source_reflection.join_primary_key].eq(through_table[source_reflection.join_foreign_key])
        else
          foreign_constraints << table[union_reflection.join_primary_key].eq(foreign_table[union_reflection.join_foreign_key])
        end
      end

      unless foreign_constraints.empty?
        foreign_constraint = foreign_constraints.reduce(&:or)

        klass_scope.where!(foreign_constraint)
      end

      unless scope_chain_items.empty?
        scope_chain_items.reduce(klass_scope) do |scope, item|
          scope.merge!(item) # e.g. default scope constraints
        end

        # FIXME(ezekg) Wrapping the where clause in a grouping node so that Rails
        #              doesn't append our left outer joins a second time. This is
        #              because internally, during joining in #join_constraints,
        #              if Rails sees an Arel::Nodes::And node with predicates that
        #              don't match the current table, it'll concat all join
        #              sources. We don't want that, thus the hack.
        klass_scope.where_clause = ActiveRecord::Relation::WhereClause.new(
          [Arel::Nodes::Grouping.new(klass_scope.where_clause.ast)],
        )
      end

      klass_scope
    end

    def deconstruct_keys(keys) = { name:, options: }
  end

  class Builder < ActiveRecord::Associations::Builder::CollectionAssociation
    private_class_method def self.valid_options(...) = %i[sources class_name inverse_of extend]
    private_class_method def self.macro              = :union_of
  end

  module Macro
    extend ActiveSupport::Concern

    class_methods do
      def union_of(name, scope = nil, **options, &extension)
        reflection = Builder.build(self, name, scope, options, &extension)

        ActiveRecord::Reflection.add_union_reflection(self, name, reflection)
        ActiveRecord::Reflection.add_reflection(self, name, reflection)
      end

      def has_many(name, scope = nil, **options, &extension)
        if sources = options.delete(:union_of)
          union_of(name, scope, **options.merge(sources:), &extension)
        else
          super
        end
      end
    end
  end

  module ReflectionExtension
    def add_union_reflection(model, name, reflection)
      model.union_reflections = model.union_reflections.merge(name.to_s => reflection)
    end

    private

    def reflection_class_for(macro)
      case macro
      when :union_of
        Reflection
      else
        super
      end
    end
  end

  module MacroReflectionExtension
    def through_union_of? = false
    def union_of?         = false
  end

  module RuntimeReflectionExtension
    delegate :union_of?, :union_sources, to: :@reflection
    delegate :name, :active_record_primary_key, to: :@reflection # FIXME(ezekg)
  end

  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    included do
      class_attribute :union_reflections, instance_writer: false, default: {}
    end

    class_methods do
      def reflect_on_all_unions = union_reflections.values
      def reflect_on_union(union)
        union_reflections[union.to_s]
      end
    end
  end

  module ThroughReflectionExtension
    delegate :union_of?, :union_sources, to: :source_reflection
    delegate :join_scope, to: :source_reflection

    def through_union_of? = through_reflection.union_of? || through_reflection.through_union_of?
  end

  module AssociationExtension
    def scope
      if reflection.union_of? || reflection.through_union_of?
        Scope.create.scope(self)
      else
        super
      end
    end
  end

  module PreloaderExtension
    def preloader_for(reflection)
      if reflection.union_of?
        Preloader::Association
      else
        super
      end
    end
  end

  module DelegationExtension
    def delegated_classes
      super << ReadonlyAssociationProxy
    end
  end

  module JoinAssociationExtension
    # Overloads Rails internals to prepend our left outer joins onto the join chain since Rails
    # unfortunately does not do this for us (it can do inner joins via the LeadingJoin arel
    # node, but it can't do outer joins because there is no LeadingOuterJoin node).
    def join_constraints(foreign_table, foreign_klass, join_type, alias_tracker)
      chain = reflection.chain.reverse
      joins = super

      # FIXME(ezekg) This is inefficient (we're recreating reflection scopes).
      chain.zip(joins).each do |reflection, join|
        klass = reflection.klass
        table = join.left

        if reflection.union_of?
          scope = reflection.join_scope(table, foreign_table, foreign_klass, alias_tracker)
          arel  = scope.arel(alias_tracker.aliases)

          # Splice union dependencies, i.e. left joins, into the join chain. This is the least
          # intrusive way of doing this, since we don't want to overload AR internals.
          unless arel.join_sources.empty?
            index = joins.index(join)

            unless (constraints = arel.constraints).empty?
              right = join.right

              right.expr = constraints # updated aliases
            end

            joins.insert(index, *arel.join_sources)
          end
        end

        # The current table in this iteration becomes the foreign table in the next
        foreign_table, foreign_klass = table, klass
      end

      joins
    end
  end

  ActiveSupport.on_load :active_record do
    include ActiveRecordExtensions

    ActiveRecord::Reflection.singleton_class.prepend(ReflectionExtension)
    ActiveRecord::Reflection::MacroReflection.prepend(MacroReflectionExtension)
    ActiveRecord::Reflection::RuntimeReflection.prepend(RuntimeReflectionExtension)
    ActiveRecord::Reflection::ThroughReflection.prepend(ThroughReflectionExtension)
    ActiveRecord::Associations::Association.prepend(AssociationExtension)
    ActiveRecord::Associations::JoinDependency::JoinAssociation.prepend(JoinAssociationExtension)
    ActiveRecord::Associations::Preloader::Branch.prepend(PreloaderExtension)
    ActiveRecord::Delegation.singleton_class.prepend(DelegationExtension)
  end
end
