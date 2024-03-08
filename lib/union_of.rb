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
      return super unless
        reflection.union_of?

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
        #
        #              How can we make this lazy? Using the #find_by_sql method
        #              immediately executes the query.
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
      return super unless
        reflection.union_of?

      table         = reflection.aliased_table
      klass         = reflection.klass
      foreign_table = next_reflection.aliased_table
      foreign_klass = next_reflection.klass
      primary_key   = reflection.active_record_primary_key
      foreign_keys  = reflection.foreign_keys

      scopes = reflection.union_sources.map do |union_source|
        union_reflection  = foreign_klass.reflect_on_association(union_source)
        union_foreign_key = union_reflection.foreign_key

        constraints = foreign_klass.default_scoped.where_clause
        foreign_key = foreign_keys[union_source]

        sources = if union_reflection.through_reflection?
                    through_reflection  = union_reflection.through_reflection
                    through_foreign_key = through_reflection.foreign_key
                    through_klass       = through_reflection.klass
                    through_table       = through_klass.arel_table
                    through_constraints = through_klass.default_scoped.where_clause

                    unless through_constraints.empty?
                      constraints = constraints.merge(through_constraints)
                    end

                    foreign_table.project(foreign_table[primary_key].as(UNION_PRIMARY_KEY), through_table[union_foreign_key].as(UNION_FOREIGN_KEY))
                                 .from(foreign_table)
                                 .join(through_table, Arel::Nodes::InnerJoin)
                                 .on(
                                   foreign_table[primary_key].eq(through_table[through_foreign_key]),
                                 )
                  else
                    foreign_table.project(foreign_table[primary_key].as(UNION_PRIMARY_KEY), foreign_table[union_foreign_key].as(UNION_FOREIGN_KEY))
                                 .from(foreign_table)
                  end

        unless constraints.empty?
          sources = sources.where(constraints.ast)
        end

        sources
      end

      union_table = Arel::Nodes::TableAlias.new(foreign_table, "#{foreign_table.name}_union")
      unions      = scopes.reduce(nil) do |left, right|
        if left
          Arel::Nodes::Union.new(left, right)
        else
          right
        end
      end

      scope.joins!(
        # Joining onto our union associations
        Arel::Nodes::LeadingJoin.new(
          Arel::Nodes::TableAlias.new(unions, union_table.name),
          Arel::Nodes::On.new(
            union_table[UNION_FOREIGN_KEY].eq(table[klass.primary_key]),
          ),
        ),
        # Joining the target association onto our union
        Arel::Nodes::LeadingJoin.new(
          foreign_table,
          Arel::Nodes::On.new(
            foreign_table[foreign_klass.primary_key].eq(union_table[UNION_PRIMARY_KEY]),
          ),
        ),
      )

      scope.merge!(
        scope.default_scoped,
      )

      scope
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

    # Unlike other reflections, we don't have a single foreign key.
    # Instead, we have many, from each union source.
    def foreign_keys = union_reflections.reduce({}) { _1.merge(_2.name => _2.foreign_key) }
    def foreign_key  = UNION_FOREIGN_KEY

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
    delegate :union_of?, :union_sources, :foreign_keys, :active_record_primary_key, to: :@reflection
    delegate :name, to: :@reflection
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
    delegate :union_of?, :union_sources, :foreign_keys, to: :source_reflection

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
    def initialize(...)
      super

      @union_references = {}
    end

    def join_constraints(foreign_table, foreign_klass, join_type, alias_tracker, &)
      case
      when reflection.through_union_of?
        join_constraints_for_through_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &)
      when reflection.union_of?
        join_constraints_for_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &)
      else
        super
      end
    end

    private

    def join_constraints_for_through_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &)
      joins = []
      chain = []

      # FIXME(ezekg) Through joins should prefix all dependent joins with the root association
      #              name, to keep them out of the way in the case of multiple union joins.
      #
      #              Granted, this seems to be a bug in Rails, not on our end.
      reflection.chain.each do |reflection|
        table, _ = @union_references.fetch(reflection.name.to_sym) { yield reflection }

        @union_references[reflection.name.to_sym] = table
        @table ||= table

        chain << [reflection, table]
      end

      chain.each_with_index.reverse_each do |(reflection, table), index|
        primary_key = reflection.active_record_primary_key
        foreign_key = reflection.foreign_key
        klass       = reflection.klass
        constraints = klass.default_scoped.where_clause

        join_reflection, join_table = chain[index + 1]
        join_klass                  = join_reflection&.klass || foreign_klass
        join_table                ||= foreign_table

        case
        when reflection.union_of?
          joins.concat(
            join_constraints_for_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &),
          )
        when reflection.belongs_to? || join_reflection&.belongs_to?
          join = join_type.new(
            table,
            Arel::Nodes::On.new(
              table[primary_key].eq(join_table[foreign_key]),
            ),
          )

          unless constraints.empty?
            append_constraints(join, [constraints.ast])
          end

          joins << join
        else
          join = join_type.new(
            table,
            Arel::Nodes::On.new(
              table[foreign_key].eq(join_table[primary_key]),
            ),
          )

          unless constraints.empty?
            append_constraints(join, [constraints.ast])
          end

          joins << join
        end
      end

      joins
    end

    def join_constraints_for_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &)
      joins = []
      chain = []

      reflection.chain.each do |reflection|
        table, _ = @union_references.fetch(reflection.name.to_sym) { yield reflection }

        @union_references[reflection.name.to_sym] = table
        @table ||= table

        chain << [reflection, table]
      end

      chain.each_with_index.reverse_each do |(reflection, table), index|
        primary_key = reflection.active_record_primary_key
        foreign_key = reflection.foreign_key
        klass       = reflection.klass
        constraints = klass.default_scoped.where_clause

        join_reflection, join_table = chain[index + 1]
        join_klass                  = join_reflection&.klass

        join_reflection ||= reflection
        join_klass      ||= foreign_klass
        join_table      ||= foreign_table

        join_primary_key = join_reflection.association_primary_key
        join_foreign_key = join_reflection.foreign_key

        case
        when reflection.union_of?
          union_sources = reflection.union_sources

          scopes = union_sources.map do |union_source|
            union_reflection  = join_klass.reflect_on_association(union_source)
            union_primary_key = union_reflection.association_primary_key
            union_foreign_key = union_reflection.foreign_key
            union_klass       = union_reflection.klass
            union_table       = union_klass.arel_table
            union_constraints = union_klass.default_scoped.where_clause

            union_scope = union_reflection.build_scope(union_table)
            union_scope = union_reflection.scope_for(union_scope) unless union_reflection.scope.nil?

            scope = case
                    when union_reflection.through_reflection?
                      source_reflection      = union_reflection.source_reflection
                      source_klass           = source_reflection.klass
                      source_table           = source_klass.arel_table
                      source_primary_key     = source_reflection.association_primary_key
                      source_foreign_key     = source_reflection.foreign_key

                      through_reflection  = union_reflection.through_reflection
                      through_klass       = through_reflection.klass
                      through_table       = through_klass.arel_table
                      through_primary_key = through_reflection.association_primary_key
                      through_foreign_key = through_reflection.foreign_key

                      through_scope = through_reflection.build_scope(through_table)
                      through_scope = through_reflection.scope_for(through_scope) unless through_reflection.scope.nil?

                      source_scope = source_reflection.build_scope(source_table)
                      source_scope = source_reflection.scope_for(source_scope) unless source_reflection.scope.nil?

                      union_constraints = through_klass.default_scoped.where_clause # adjust default constraints
                      union_scope       = through_scope.merge(union_scope)
                      union_arel        = union_scope.arel

                      union_arel.projections.clear
                      union_arel.project(
                        through_table[source_foreign_key].as(UNION_PRIMARY_KEY),
                        through_table[through_foreign_key].as(UNION_FOREIGN_KEY),
                      )
                    when union_reflection.belongs_to?
                      # We never want to alias union tables
                      unaliased_table = case join_table
                                        in Arel::Nodes::TableAlias => t
                                          t.left
                                        in Arel::Table => t
                                          t
                                        end

                      join_scope = join_reflection.build_scope(unaliased_table)
                      join_scope = join_reflection.scope_for(join_scope) unless join_reflection.scope.nil?

                      union_constraints = join_klass.default_scoped.where_clause # adjust default constraints
                      union_arel        = join_scope.arel

                      union_arel.projections.clear
                      union_arel.project(
                        unaliased_table[union_foreign_key].as(UNION_PRIMARY_KEY),
                        unaliased_table[union_primary_key].as(UNION_FOREIGN_KEY),
                      )
                    else
                      union_arel = union_scope.arel

                      union_arel.projections.clear
                      union_arel.project(
                        union_table[:id].as(UNION_PRIMARY_KEY),
                        union_table[union_foreign_key].as(UNION_FOREIGN_KEY),
                      )
                    end

            unless union_constraints.empty?
              scope = scope.where(union_constraints.ast)
            end

            scope
          end

          # We need to unalias the table so that we can properly create a union table alias
          unaliased_table = case table
                            in Arel::Nodes::TableAlias => t
                              t.left
                            in Arel::Table => t
                              t
                            end

          union_table = alias_tracker.aliased_table_for(unaliased_table, "#{unaliased_table.name}_union") {
            # FIXME(ezekg) Is this the best way to handle conflicts? The name will be auto
            #              incremented, but MAY produce bad joins, depending on order.
            #
            #              Could we just skip the new join and reuse the old one?
            "#{unaliased_table.name}_union"
          }

          unions = scopes.reduce(nil) do |left, right|
            if left
              Arel::Nodes::Union.new(left, right)
            else
              right
            end
          end

          # Joining onto our union associations
          joins << join_type.new(
            Arel::Nodes::TableAlias.new(unions, union_table.name),
            Arel::Nodes::On.new(
              union_table[UNION_FOREIGN_KEY].eq(join_table[join_klass.primary_key]),
            ),
          )

          # Joining the target association onto our union
          join = join_type.new(
            table,
            Arel::Nodes::On.new(
              table[klass.primary_key].eq(union_table[klass.primary_key]),
            ),
          )

          unless constraints.empty?
            append_constraints(join, [constraints.ast])
          end

          joins << join
        when reflection.belongs_to? || join_reflection&.belongs_to?
          join = join_type.new(
            table,
            Arel::Nodes::On.new(
              table[primary_key].eq(join_table[foreign_key]),
            ),
          )

          unless constraints.empty?
            append_constraints(join, [constraints.ast])
          end

          joins << join
        else
          join = join_type.new(
            table,
            Arel::Nodes::On.new(
              table[foreign_key].eq(join_table[primary_key]),
            ),
          )

          unless constraints.empty?
            append_constraints(join, [constraints.ast])
          end

          joins << join
        end
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
