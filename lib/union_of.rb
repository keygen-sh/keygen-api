# frozen_string_literal: true

require 'active_record_union'

module UnionOf
  class ReadonlyAssociation < ActiveRecord::Associations::CollectionAssociation
    # TODO(ezekg) Implement a readonly association. Raise proper errors.

    def writer(...)      = raise NotImplementedError
    def ids_writer       = raise NotImplementedError
    def destroy_all(...) = raise NotImplementedError
    def delete_all(...)  = raise NotImplementedError

    def insert_record(...)  = raise NotImplementedError
    def delete_records(...) = raise NotImplementedError
    def concat_records(...) = raise NotImplementedError
    def build_record(...)   = raise NotImplementedError
  end

  class Association < ReadonlyAssociation
    def association_scope = Scope.scope(self)
  end

  class ThroughAssociation < Association
    include ActiveRecord::Associations::ThroughAssociation
  end

  class Scope < ActiveRecord::Associations::AssociationScope
    INSTANCE = create

    def self.scope(association)
      INSTANCE.scope(association)
    end

    private

    def last_chain_scope(scope, reflection, owner)
      return super unless
        reflection.union_of?

      foreign_table = reflection.aliased_table
      foreign_key   = reflection.join_foreign_key

      sources = reflection.union_sources.map do |source|
        association = owner.association(source)
        reflection  = association.reflection
        primary_key = reflection.active_record_primary_key

        # FIXME(ezekg) Should we use Arel here instead of this private API?
        association.send(:association_scope)
                   .select(primary_key)
                   .unscope(:order)
                   .arel
      end

      unions = sources.reduce(nil) do |left, right|
        if left
          Arel::Nodes::Union.new(left, right)
        else
          right
        end
      end

      scope.where!(
        foreign_table[foreign_key].in(
          foreign_table.project(foreign_table[foreign_key])
                       .from(
                         Arel::Nodes::TableAlias.new(unions, foreign_table.name),
                       ),
        ),
      )

      scope.merge(
        scope.default_scoped,
      )
    end

    def next_chain_scope(scope, reflection, next_reflection)
      return super unless
        reflection.union_of?

      table = reflection.aliased_table
      klass = reflection.klass
      foreign_table = next_reflection.aliased_table
      foreign_klass = next_reflection.klass
      primary_key = reflection.join_primary_key
      foreign_key = reflection.join_foreign_key

      scopes = reflection.union_sources.map do |union_source|
        union_source_reflection  = foreign_klass.reflect_on_association(union_source)
        union_source_foreign_key = union_source_reflection.foreign_key

        if union_source_reflection.through_reflection?
          through_reflection  = union_source_reflection.through_reflection
          through_foreign_key = through_reflection.foreign_key
          through_klass       = through_reflection.klass
          through_table       = through_klass.arel_table

          foreign_table.project(foreign_table[foreign_key])
                       .from(foreign_table)
                       .join(through_table, Arel::Nodes::InnerJoin)
                       .on(
                         table[foreign_key].eq(through_table[union_source_foreign_key]),
                         foreign_table[foreign_key].eq(through_table[through_foreign_key]),
                       )
        else
          foreign_table.project(foreign_table[foreign_key])
                       .from(foreign_table)
                       .where(
                         table[foreign_key].eq(foreign_table[union_source_foreign_key]),
                       )
        end
      end

      unions = scopes.reduce(nil) do |left, right|
        if left
          Arel::Nodes::Union.new(left, right)
        else
          right
        end
      end

      scope.joins!(
        join(
          foreign_table,
          foreign_table[foreign_key].in(
            unions,
          ),
        ),
      )

      scope.merge(
        scope.default_scoped,
      )
    end
  end

  class Reflection < ActiveRecord::Reflection::AssociationReflection
    attr_reader :union_sources

    def initialize(...)
      super

      @union_sources = @options[:sources]

      # FIXME(ezekg) Remove this workaround and add a proper klass lookup.
      # TODO(ezekg) Add polymorphic support?
      @klass ||= @union_sources.map { active_record._reflect_on_association(_1).klass }
                               .uniq
                               .sole
    end

    def macro       = :union_of
    def union_of?   = true
    def collection? = true

    def association_class
      if options[:through]
        ThroughAssociation
      else
        Association
      end
    end

    def association_scope
      return if klass.nil?

      Scope.create(self)
    end

    def join_scope(table, foreign_table, foreign_klass)
      predicate_builder = predicate_builder(table)
      scope_chain_items = join_scopes(table, predicate_builder)
      klass_scope       = klass_join_scope(table, predicate_builder)

      klass_scope.where!(
        join_foreign_key => union_sources.reduce(nil) do |chain, union_source|
          reflection = foreign_klass.reflect_on_association(union_source)
          relation   = reflection.klass.scope_for_association.except(:order)
                                                             .select(:id)

          primary_key = reflection.join_primary_key
          foreign_key = reflection.join_foreign_key

          scope = if reflection.through_reflection?
                    through_reflection  = reflection.through_reflection
                    through_foreign_key = through_reflection.foreign_key
                    through_klass       = through_reflection.klass
                    through_table       = through_klass.arel_table

                    # FIXME(ezekg) Seems like there should be a better way to do this?
                    unaliased_table = case table
                                      in Arel::Nodes::TableAlias => aliased_table
                                        Arel::Table.new(aliased_table.right)
                                      in Arel::Table => table
                                        table
                                      end

                    join_sources = unaliased_table.join(through_table, Arel::Nodes::InnerJoin)
                                                  .from(table)
                                                  .on(
                                                    table[primary_key].eq(through_table[foreign_key]),
                                                    foreign_table[primary_key].eq(through_table[through_foreign_key]),
                                                  )
                                                  .join_sources

                    relation.joins(join_sources)
                  else
                    relation.where(table[primary_key].eq(foreign_table[foreign_key]))
                  end

          if chain
            chain.union(scope)
          else
            scope
          end
        end
      )
    end

    def can_find_inverse_of_automatically?(...) = false

    def deconstruct_keys(keys) = { name:, options: }
  end

  class Builder < ActiveRecord::Associations::Builder::CollectionAssociation
    private_class_method def self.valid_options(...) = %i[sources class_name extend]
    private_class_method def self.macro              = :union_of

    def self.define_writers(...)
      # noop
    end
  end

  module Macro
    extend ActiveSupport::Concern

    class_methods do
      def union_of(name, scope = nil, **options, &extension)
        # TODO(ezekg) Validate sources against association reflections.

        reflection = Builder.build(self, name, scope, options, &extension)

        ActiveRecord::Reflection.add_union_reflection(self, name, reflection)
        ActiveRecord::Reflection.add_reflection(self, name, reflection)
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
    def union_of? = false
  end

  module RuntimeReflectionExtension
    delegate :union_of?, :union_sources, to: :@reflection
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

    def through_union_of? = through_reflection.union_of? || (through_reflection.through_reflection? && through_reflection.through_union_of?)
    def join_scope(...)
      if union_of?
        source_reflection.join_scope(...)
      else
        super
      end
    end
  end

  module AssociationExtension
    def scope
      if reflection.union_of? || (reflection.through_reflection? && reflection.through_union_of?)
        Scope.create.scope(self)
      else
        super
      end
    end
  end

  ActiveRecord::Reflection.singleton_class.prepend(ReflectionExtension)
  ActiveRecord::Reflection::MacroReflection.prepend(MacroReflectionExtension)
  ActiveRecord::Reflection::RuntimeReflection.prepend(RuntimeReflectionExtension)
  ActiveRecord::Reflection::ThroughReflection.prepend(ThroughReflectionExtension)
  ActiveRecord::Associations::Association.prepend(AssociationExtension)
  ActiveRecord::Base.include(ActiveRecordExtensions)
end
