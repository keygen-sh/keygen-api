# frozen_string_literal: true

module UnionOf
  UNION_ID = 'union_id'.freeze

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

      scope.where!(
        foreign_table[primary_key].in(
          foreign_table.project(foreign_table[primary_key])
                       .from(
                         Arel::Nodes::TableAlias.new(unions, foreign_table.name),
                       ),
        ),
      )

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

                    foreign_table.project(foreign_table[primary_key], through_table[union_foreign_key].as(UNION_ID))
                                  .from(foreign_table)
                                  .join(through_table, Arel::Nodes::InnerJoin)
                                  .on(
                                    foreign_table[primary_key].eq(through_table[through_foreign_key]),
                                  )
                  else
                    foreign_table.project(foreign_table[primary_key], foreign_table[union_foreign_key].as(UNION_ID))
                                  .from(foreign_table)
                  end

        unless constraints.empty?
          sources = sources.where(constraints.ast)
        end

        sources
      end

      unions = scopes.reduce(nil) do |left, right|
        if left
          Arel::Nodes::Union.new(left, right)
        else
          right
        end
      end

      scope.joins!(
        Arel::Nodes::LeadingJoin.new(
          Arel::Nodes::TableAlias.new(unions, foreign_table.name),
          Arel::Nodes::On.new(
            foreign_table[UNION_ID].eq(table[primary_key]),
          ),
        )
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
    def foreign_key  = :union_id
    def foreign_keys = union_reflections.reduce({}) { _1.merge(_2.name => _2.foreign_key) }
    # def foreign_keys
    #   union_reflections.reduce({}) do |hash, reflection|
    #     if reflection.through_reflection?
    #       through_reflection = reflection.through_reflection

    #       hash.merge(reflection.name => through_reflection.foreign_key)
    #     else
    #       hash.merge(reflection.name => reflection.foreign_key)
    #     end
    #   end
    # end

    # def collect_join_chain
    #   [self] + union_reflections.flat_map(&:chain)
    # end

    # def join_scope(table, foreign_table, foreign_klass)
    #   pp(join_scope: Time.now.to_i, caller: caller.first(25))

    #   predicate_builder = predicate_builder(table)
    #   scope_chain_items = join_scopes(table, predicate_builder)
    #   scope             = klass_join_scope(table, predicate_builder)

    #   scopes = union_sources.map do |union_source|
    #     union_reflection = foreign_klass.reflect_on_association(union_source)
    #     union_relation   = union_reflection.klass.scope_for_association.select(union_reflection.active_record_primary_key)
    #                                                                    .except(:order)

    #     primary_key = union_reflection.join_primary_key
    #     foreign_key = union_reflection.join_foreign_key

    #     if union_reflection.through_reflection?
    #         through_reflection  = union_reflection.through_reflection
    #         through_foreign_key = through_reflection.foreign_key
    #         through_klass       = through_reflection.klass
    #         through_table       = through_klass.arel_table

    #         # FIXME(ezekg) Seems like there should be a better way to do this?
    #         unaliased_table = case table
    #                           in Arel::Nodes::TableAlias => aliased_table
    #                             Arel::Table.new(aliased_table.right)
    #                           in Arel::Table => table
    #                             table
    #                           end

    #         join_sources = unaliased_table.join(through_table, Arel::Nodes::InnerJoin)
    #                                       .from(table)
    #                                       .on(
    #                                         table[primary_key].eq(through_table[foreign_key]),
    #                                         foreign_table[primary_key].eq(through_table[through_foreign_key]),
    #                                       )
    #                                       .join_sources

    #         union_relation.joins(join_sources)
    #                       .arel
    #       else
    #         union_relation.where(table[primary_key].eq(foreign_table[foreign_key]))
    #                       .arel
    #       end
    #   end

    #   unions = scopes.reduce(nil) do |left, right|
    #     if left
    #       Arel::Nodes::Union.new(left, right)
    #     else
    #       right
    #     end
    #   end

    #   scope.where!(
    #     table[join_foreign_key].in(
    #       unions,
    #     )
    #   )

    #   # scope.joins!(
    #   #   Arel::Nodes::LeadingJoin.new(
    #   #     Arel::Nodes::TableAlias.new(unions, foreign_table.name),
    #   #     Arel::Nodes::On.new(
    #   #       Arel::Nodes::True.new,
    #   #       # foreign_table[UNION_ID].eq(table[foreign_key]),
    #   #     ),
    #   #   )
    #   # )

    #   scope.merge!(
    #     scope.default_scoped,
    #   )

    #   # pp(sql: scope.dup.to_sql)

    #   scope
    # end

    # def join_scope(table, foreign_table, foreign_klass)
    #   predicate_builder = predicate_builder(table)
    #   scope_chain_items = join_scopes(table, predicate_builder)
    #   klass_scope       = klass_join_scope(table, predicate_builder)

    #   scope_chain_items.inject(klass_scope, &:merge!)

    #   # NOTE(ezekg) This union is joined earlier in the chain via #union_joins!
    #   union_table = derive_union_table(table, foreign_table, foreign_klass)
    #   primary_key = klass.primary_key

    #   klass_scope.where!(
    #     union_table[primary_key].eq(table[primary_key]),
    #   )

    #   klass_scope
    # end

    def deconstruct_keys(keys) = { name:, options: }

    private

    # def derive_union_table(table, foreign_table, foreign_klass)
    #   Arel::Table.new(:"#{table.name}_union")
    # end
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

    # def join_scope(...)
    #   if union_of?
    #     source_reflection.join_scope(...)
    #   else
    #     super
    #   end
    # end
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

  module RelationExtension
    def union_joins_values = @values.fetch(:union_joins) { ActiveRecord::Relation::FROZEN_EMPTY_ARRAY }
    def union_joins_values=(value)
      assert_mutability!

      @values[:union_joins] = value
    end
  end

  module QueryMethodsExtension
    def union_joins(*args)
      check_if_method_has_arguments!(__callee__, args)

      spawn.union_joins!(*args)
    end

    def union_joins!(*args)
      self.union_joins_values |= args

      self
    end

    # FIXME(ezekg) Call union_joins! when arg is a union association. To make this call
    #              fast, perhaps keep a map of union associations?
    def joins!(*args)
      super
    end

    def left_outer_joins!(*args)
      super
    end

    private

    # def build_arel(aliases = nil)
    #   arel = super

    #   arel
    # end

    # def build_joins(join_sources, aliases = nil)
    #   return join_sources if joins_values.empty? && left_outer_joins_values.empty? && union_joins_values.empty?

    #   buckets, join_type = build_join_buckets

    #   named_joins   = buckets[:named_join]
    #   stashed_joins = buckets[:stashed_join]
    #   leading_joins = buckets[:leading_join]
    #   join_nodes    = buckets[:join_node]

    #   join_sources.concat(leading_joins) unless leading_joins.empty?

    #   unless named_joins.empty? && stashed_joins.empty?
    #     alias_tracker = alias_tracker(leading_joins + join_nodes, aliases)
    #     join_dependency = construct_join_dependency(named_joins, join_type)
    #     join_sources.concat()
    #   end

    #   join_sources.concat(join_nodes) unless join_nodes.empty?
    #   join_sources
    # end

    def build_joins(join_sources, aliases = nil)
      self.joins_values |= union_joins_values
      super
      # return super if union_joins_values.empty?

      # join_sources = super

      # # FIXME(ezekg) We need to iterate each union join value so we can make sense
      # #              of multiple join chains
      # union_joins_values.each do |association|
      #   reflection = klass.reflect_on_association(association)
      #   chain      = reflection.chain

      #   pp(
      #     reflection: reflection.name,
      #     union_of?: reflection.union_of?,
      #     through_union_of?: reflection.through_union_of?,
      #     chain: chain.collect(&:name),
      #   )

      #   joins = chain.reverse_each.map do |reflection|
      #     foreign_klass = reflection.klass
      #     foreign_table = foreign_klass.arel_table

      #     if reflection.union_of?
      #       scopes = [
      #         Arel.sql('select 1 from licenses limit 1'),
      #         Arel.sql('select 2 from licenses limit 1'),
      #         Arel.sql('select 3 from licenses limit 1'),
      #       ]

      #       union_table = Arel::Table.new(:"#{foreign_table.name}_union")
      #       unions      = scopes.reduce(nil) do |left, right|
      #         if left
      #           Arel::Nodes::Union.new(left, right)
      #         else
      #           right
      #         end
      #       end

      #       Arel::Nodes::LeadingJoin.new(
      #         Arel::Nodes::TableAlias.new(unions, union_table.name),
      #         Arel::Nodes::On.new(
      #           union_table[UNION_ID].eq(table[klass.primary_key]),
      #         ),
      #       )
      #     else
      #       reflection.name
      #     end
      #   end


      #   puts klass.joins(joins).to_sql

      #   # union_joins, through_joins = chain.partition(&:union_of?)
      #   # union_association = union_joins.collect(&:name)
      #   # through_associations = through_joins.collect(&:name)
      #   # pp(union_association:, through_associations:)



      #   # through_join_dependency = construct_join_dependency(through_associations, Arel::Nodes::InnerJoin)
      #   # through_join_source = through_join_dependency.join_constraints([], alias_tracker, [])

      #   # puts klass.joins(through_join_source).to_sql

      #   # join_dependency = construct_join_dependency(association, Arel::Nodes::InnerJoin)
      #   # join_source     = join_dependency.join_constraints([], alias_tracker, [])

      #   # puts klass.joins(join_source).to_sql

      #   # # TODO(ezekg) Insert a leading join for the union
      #   # #
      #   # # INNER JOIN (
      #   # #   (
      #   # #     SELECT
      #   # #       "licenses"."id",
      #   # #       "license_users"."user_id" AS union_id
      #   # #     FROM
      #   # #       "licenses"
      #   # #       INNER JOIN "license_users" ON "licenses"."id" = "license_users"."license_id"
      #   # #   )
      #   # #   UNION
      #   # #   (
      #   # #     SELECT
      #   # #       "licenses"."id",
      #   # #       "licenses"."user_id" AS union_id
      #   # #     FROM
      #   # #       "licenses"
      #   # #   )
      #   # # ) "licenses_union" ON "licenses_union"."union_id" = "users"."id"
      #   # #
      #   # foreign_table = join_source.find { _1.right.value.left.relation.name.ends_with?("_union") rescue nil }&.left
      #   # pp(tables: join_source.map { _1.right.value.left.relation.name rescue nil })
      #   # foreign_klass = foreign_table.instance_variable_get(:@klass) # FIXME(ezekg)

      #   # union_join_source = build_union_join_source(association, foreign_table, foreign_klass)

      #   # join_source.unshift(union_join_source) # splice in union sources
      #   # join_sources.concat(join_source)
      # end

      # join_sources
    end

    def union_reflection_for(association)
      reflection = klass.reflect_on_association(association)

      case
      when reflection.through_union_of?
        through_reflection = reflection.through_reflection

        # All intermediary reflections are already joined normally. We just
        # need the source of the union reflection so that we can craft
        # a UNION across all union sources for each association.
        until through_reflection.union_of?
          through_reflection = through_reflection.through_reflection
        end

        through_reflection
      when reflection.union_of?
        reflection
      else
        []
      end
    end

    def build_union_join_source(association, foreign_table, foreign_klass)
      reflection   = union_reflection_for(association)
      primary_key  = reflection.active_record_primary_key
      foreign_keys = reflection.foreign_keys

      # pp(reflection: reflection.name, union_sources: reflection.union_sources, inverse_of: reflection.inverse_of&.name, through?: reflection.through_reflection?, union_of?: reflection.union_of?, through_union_of?: reflection.through_union_of?)

      # if reflection.through_reflection?
      #   through_reflection = reflection.through_reflection
      #   pp(through_reflection: through_reflection.name, union_of?: through_reflection.union_of?, through_union_of?: through_reflection.through_union_of?)
      # end

      # scopes = reflection.union_sources.map do |union_source|
      #   union_reflection  = klass.reflect_on_association(union_source) || foreign_klass.reflect_on_association(union_source) # FIXME(ezekg)
      #   union_foreign_key = union_reflection&.foreign_key
      #   pp(union_source:, union_reflection: union_reflection&.name)

      #   constraints = foreign_klass.default_scoped.where_clause
      #   foreign_key = foreign_keys[union_source]

      #   sources = if union_reflection.through_reflection?
      #               through_reflection  = union_reflection.through_reflection
      #               through_foreign_key = through_reflection.foreign_key
      #               through_klass       = through_reflection.klass
      #               through_table       = through_klass.arel_table
      #               through_constraints = through_klass.default_scoped.where_clause

      #               unless through_constraints.empty?
      #                 constraints = constraints.merge(through_constraints)
      #               end

      #               foreign_table.project(foreign_table[primary_key], through_table[union_foreign_key].as(UNION_ID))
      #                             .from(foreign_table)
      #                             .join(through_table, Arel::Nodes::InnerJoin)
      #                             .on(
      #                               foreign_table[primary_key].eq(through_table[through_foreign_key]),
      #                             )
      #             else
      #               foreign_table.project(foreign_table[primary_key], foreign_table[union_foreign_key].as(UNION_ID))
      #                             .from(foreign_table)
      #             end

      #   unless constraints.empty?
      #     sources = sources.where(constraints.ast)
      #   end

      #   sources
      # end

      union_table = Arel::Table.new(:"#{foreign_table.name}_union")
      unions      = scopes.reduce(nil) do |left, right|
        if left
          Arel::Nodes::Union.new(left, right)
        else
          right
        end
      end

      Arel::Nodes::LeadingJoin.new(
        Arel::Nodes::TableAlias.new(unions, union_table.name),
        Arel::Nodes::On.new(
          union_table[UNION_ID].eq(table[klass.primary_key]),
        ),
      )
    end

    # def build_join_buckets
    #   buckets, join_type = super

    #   while union_joins_values.first.is_a?(Arel::Nodes::Join)
    #     join_node = union_joins_values.shift
    #     if !join_node.is_a?(Arel::Nodes::LeadingJoin) && (stashed_eager_load || stashed_left_joins)
    #       buckets[:join_node] << join_node
    #     else
    #       buckets[:leading_join] << join_node
    #     end
    #   end

    #   buckets[:named_join] = select_named_joins(union_joins_values, buckets[:stashed_join]) do |join|
    #     if join.is_a?(Arel::Nodes::Join)
    #       buckets[:join_node] << join
    #     elsif join.is_a?(CTEJoin)
    #       buckets[:join_node] << build_with_join_node(join.name)
    #     else
    #       raise "unknown class: %s" % join.class.name
    #     end
    #   end

    #   return buckets, join_type
    # end
  end

  module QueryingExtension
    delegate :union_joins, :union_joins!, to: :all
  end

  module JoinDependencyExtension
    # def initialize(base, table, associations, join_type)
    #   pp(base: base.name, table: table.name, associations:, join_type: join_type&.name)

    #   super
    # end
  end

  module JoinAssociationExtension
    # def initialize(reflection, children)
    #   @table = reflection.klass.arel_table

    #   super
    # end

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

    def join_constraints_for_through_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &)
      joins = []
      chain = []

      reflection.chain.each do |reflection|
        table, _ = yield reflection
        @table ||= table

        # FIXME(ezekg) Aliasing unions isn't working properly
        if reflection.union_of?
          table = reflection.klass.arel_table
        end

        chain << [reflection, table]
      end

      chain.each_with_index.reverse_each do |(reflection, table), index|
        primary_key = reflection.active_record_primary_key
        foreign_key = reflection.foreign_key
        klass       = reflection.klass

        join_reflection, join_table = chain[index + 1]
        join_klass                  = join_reflection&.klass || foreign_klass
        join_table                ||= foreign_table

        case
        when reflection.union_of?
          joins.concat(
            join_constraints_for_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &),
          )
        # FIXME(ezekg) Add default constraints for association
        when reflection.belongs_to? || join_reflection&.belongs_to?
          joins << join_type.new(
            table,
            Arel::Nodes::On.new(
              table[primary_key].eq(join_table[foreign_key]),
            ),
          )
        else
          joins << join_type.new(
            table,
            Arel::Nodes::On.new(
              table[foreign_key].eq(join_table[primary_key]),
            ),
          )
        end
      end

      joins
    end

    def join_constraints_for_union(reflection, foreign_table, foreign_klass, join_type, alias_tracker, &)
      joins = []
      chain = []

      reflection.chain.each do |reflection|
        table, _ = yield reflection
        @table ||= table

        # FIXME(ezekg) Aliasing unions isn't working properly
        if reflection.union_of?
          table = reflection.klass.arel_table
        end

        chain << [reflection, table]
      end

      chain.each_with_index.reverse_each do |(reflection, table), index|
        primary_key = reflection.active_record_primary_key
        foreign_key = reflection.foreign_key
        klass       = reflection.klass

        join_reflection, join_table = chain[index + 1]
        join_klass                  = join_reflection&.klass || foreign_klass
        join_table                ||= foreign_table

        case
        when reflection.union_of?
          union_sources = reflection.union_sources

          scopes = union_sources.map do |union_source|
            union_reflection = join_klass.reflect_on_association(union_source)

            # FIXME(ezekg) Add default constraints for association
            case
            when union_reflection.through_reflection?
              source_table           = union_reflection.source_reflection.klass.arel_table
              unaliased_source_table = unaliased_table(source_table)
              source_primary_key     = union_reflection.source_reflection.association_primary_key
              source_foreign_key     = union_reflection.source_reflection.foreign_key

              through_table       = union_reflection.through_reflection.klass.arel_table
              through_foreign_key = union_reflection.through_reflection.foreign_key

              unaliased_source_table.project(
                                      source_table[:id].as('id'),
                                      through_table[through_foreign_key].as('union_id'),
                                    )
                                    .join(
                                      through_table,
                                      Arel::Nodes::InnerJoin,
                                    )
                                    .on(
                                      source_table[source_primary_key].eq(through_table[source_foreign_key]),
                                    )
            when union_reflection.belongs_to?
              unaliased_table = unaliased_table(table)
              foreign_key     = union_reflection.foreign_key

              unaliased_table.project(
                                table[:id].as('id'),
                                join_table[:id].as('union_id'),
                              )
                              .join(
                                join_table,
                                Arel::Nodes::InnerJoin,
                              )
                              .on(
                                table[:id].eq(join_table[foreign_key]),
                              )
            else
              unaliased_table = unaliased_table(table)
              foreign_key     = union_reflection.foreign_key

              unaliased_table.project(
                                table[:id].as('id'),
                                table[foreign_key].as('union_id'),
                              )
            end
          end

          unaliased_table = unaliased_table(table)
          union_table = alias_tracker.aliased_table_for(unaliased_table, "#{unaliased_table.name}_union")
          unions      = scopes.reduce(nil) do |left, right|
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
              union_table[UNION_ID].eq(join_table[join_klass.primary_key]),
            ),
          )

          # Joining the target association onto our union
          joins << join_type.new(
            table,
            Arel::Nodes::On.new(
              table[klass.primary_key].eq(union_table[klass.primary_key]),
            ),
          )
        # FIXME(ezekg) Add default constraints for association
        when reflection.belongs_to? || join_reflection&.belongs_to?
          joins << join_type.new(
            table,
            Arel::Nodes::On.new(
              table[primary_key].eq(join_table[foreign_key]),
            ),
          )
        else
          joins << join_type.new(
            table,
            Arel::Nodes::On.new(
              table[foreign_key].eq(join_table[primary_key]),
            ),
          )
        end
      end

      joins
    end

    def unaliased_table(table)
      case table
      in Arel::Nodes::TableAlias => aliased_table
        Arel::Table.new(aliased_table.right)
      in Arel::Table => table
        table
      end
    end

    # def join_constraints(foreign_table, foreign_klass, join_type, alias_tracker)
      # joins = []
      # chain = []

      # reflection.chain.each do |reflection|
      #   table, terminated = yield reflection
      #   @table ||= table

      #   if terminated
      #     foreign_table, foreign_klass = table, reflection.klass
      #     break
      #   end

      #   chain << [reflection, table]
      # end

      # # The chain starts with the target table, but we want to end with it here (makes
      # # more sense in this context), so we reverse
      # chain.reverse_each do |reflection, table|
      #   klass = reflection.klass

      #   scope = reflection.join_scope(table, foreign_table, foreign_klass)

      #   unless scope.references_values.empty?
      #     associations = scope.eager_load_values | scope.includes_values

      #     unless associations.empty?
      #       scope.joins! scope.construct_join_dependency(associations, Arel::Nodes::OuterJoin)
      #     end
      #   end

      #   arel = scope.arel(alias_tracker.aliases)
      #   nodes = arel.constraints.first

      #   if nodes.is_a?(Arel::Nodes::And)
      #     others = nodes.children.extract! do |node|
      #       !Arel.fetch_attribute(node) { |attr| attr.relation.name == table.name }
      #     end
      #   end

      #   joins << join_type.new(table, Arel::Nodes::On.new(nodes))

      #   if others && !others.empty?
      #     joins.concat arel.join_sources
      #     append_constraints(joins.last, others)
      #   end

      #   # The current table in this iteration becomes the foreign table in the next
      #   foreign_table, foreign_klass = table, klass
      # end

      # joins
    # end
  end

  ActiveSupport.on_load :active_record do
    include ActiveRecordExtensions

    ActiveRecord::Reflection.singleton_class.prepend(ReflectionExtension)
    ActiveRecord::Reflection::MacroReflection.prepend(MacroReflectionExtension)
    ActiveRecord::Reflection::RuntimeReflection.prepend(RuntimeReflectionExtension)
    ActiveRecord::Reflection::ThroughReflection.prepend(ThroughReflectionExtension)
    ActiveRecord::Associations::Association.prepend(AssociationExtension)
    ActiveRecord::Associations::Preloader::Branch.prepend(PreloaderExtension)
    ActiveRecord::Delegation.singleton_class.prepend(DelegationExtension)
    ActiveRecord::Relation.prepend(RelationExtension)
    ActiveRecord::QueryMethods.prepend(QueryMethodsExtension)
    ActiveRecord::Querying.prepend(QueryingExtension)
    ActiveRecord::Associations::JoinDependency.prepend(JoinDependencyExtension)
    ActiveRecord::Associations::JoinDependency::JoinAssociation.prepend(JoinAssociationExtension)
  end
end
