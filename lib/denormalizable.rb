# frozen_string_literal: true

module Denormalizable
  class Error < StandardError; end
  class AssociationNotFoundError < Error; end
  class InverseAssociationNotFoundError < Error; end

  DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE = 1_000

  ##
  # Model is the concern included into models that denormalize attributes.
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :denormalizations, default: {}, instance_accessor: false
    end

    class_methods do
      def denormalizes(*attribute_names, from: nil, to: nil, through: nil, polymorphic: nil, inverse_of: nil, prefix: nil, as: nil)
        raise ArgumentError, 'must provide either :from or :to (but not both)' unless
          from.present? ^ to.present?

        raise ArgumentError, 'must provide :through when using :polymorphic' if
          polymorphic.present? && through.blank?

        raise ArgumentError, 'must provide :to and :through when using :inverse_of' if
          inverse_of.present? && (to.blank? || through.blank?)

        raise ArgumentError, 'must provide either :prefix or :as (but not both)' if
          prefix.present? && as.present?

        raise ArgumentError, 'must provide a single attribute when using :as' if
          as.present? && attribute_names.many?

        attribute_names.each do |attribute_name|
          denormalization = if from.present?
                              Denormalization::From.new(self, attribute: attribute_name, association: Association.build(self, from, kind: :from, through:, polymorphic:), prefix:, as:)
                            else
                              Denormalization::To.new(self, attribute: attribute_name, association: Association.build(self, to, kind: :to, through:, polymorphic:, inverse_of:), prefix:, as:)
                            end

          denormalization.instrument!

          self.denormalizations = denormalizations.merge(denormalization.key => denormalization.freeze)
        end
      end

      def denormalized_attributes = denormalizations.keys.to_set
    end
  end

  ##
  # Association resolves the records a denormalized attribute is read from or
  # written to, encapsulating reflection, resolution, change tracking and
  # ownership so that denormalizations don't need to care how records are
  # reached.
  class Association
    attr_reader :model, :name, :reflection

    # build returns the association for the given name: a Singular or
    # Collection for an association declared on the model itself, or a
    # Through when the records are resolved via a method on the :through
    # association's record.
    def self.build(model, name, kind:, through: nil, polymorphic: nil, inverse_of: nil)
      if through.present?
        reflection = model.reflect_on_association(through)
        raise ArgumentError, "invalid :through association: #{through.inspect}" if
          reflection.nil?

        raise ArgumentError, "must be a singular association: #{through.inspect}" if
          reflection.collection?

        collection = if reflection.polymorphic?
                       # NB(ezekg) a polymorphic :through can't be reflected on, so the
                       #           resolved records' macro must be explicitly declared
                       #           via :polymorphic (a :from source is singular by
                       #           definition, so it may be omitted there)
                       raise ArgumentError, "invalid :polymorphic macro: #{polymorphic.inspect}" unless
                         polymorphic in nil | true | :has_many | :has_one | :belongs_to

                       case kind
                       in :from
                         raise ArgumentError, "must be a singular association: #{name.inspect}" if
                           polymorphic in true | :has_many

                         false
                       in :to
                         raise ArgumentError, "must provide :polymorphic for a polymorphic :through association: #{through.inspect}" if
                           polymorphic.nil?

                         polymorphic in true | :has_many
                       end
                     else
                       raise ArgumentError, "cannot use :polymorphic for a non-polymorphic :through association: #{through.inspect}" if
                         polymorphic.present?

                       target_reflection = reflection.klass.reflect_on_association(name)

                       case
                       when target_reflection.present?
                         target_reflection.collection?
                       when kind == :from
                         # a :from source may be a plain method on the :through record
                         # and is singular by definition
                         false
                       else
                         raise ArgumentError, "invalid :to association: #{name.inspect} for #{reflection.klass}"
                       end
                     end

        raise ArgumentError, "must be a singular association: #{name.inspect}" if
          collection && kind == :from

        raise ArgumentError, "must be a collection association when using :inverse_of: #{name.inspect}" if
          inverse_of.present? && !collection

        if collection
          Through::Collection.new(model, name, reflection:, inverse_of:)
        else
          Through::Singular.new(model, name, reflection:)
        end
      else
        reflection = model.reflect_on_association(name)
        raise ArgumentError, "invalid :#{kind} association: #{name.inspect}" if
          reflection.nil?

        if reflection.collection?
          Collection.new(model, name, reflection:)
        else
          Singular.new(model, name, reflection:)
        end
      end
    end

    def initialize(model, name, reflection:)
      @model      = model
      @name       = name
      @reflection = reflection
    end

    def collection? = reflection.collection?

    # changed_condition returns a callable condition that returns true when
    # the association has changed, via its foreign keys or target record.
    def changed_condition
      association_name = reflection.name

      foreign_keys  = Array(reflection.foreign_key)
      foreign_keys += [reflection.foreign_type] if reflection.polymorphic?

      -> record { foreign_keys.any? { record.public_send(:"#{it}_changed?") } || record.public_send(:"#{association_name}_changed?") }
    end
  end

  ##
  # Association::Direct is an association declared on the model itself, i.e.
  # its reflection is the association itself.
  class Association::Direct < Association
    def resolve(record) = record.public_send(name)
  end

  ##
  # Association::Singular is a direct singular association, e.g. a belongs_to
  # or has_one.
  class Association::Singular < Association::Direct
    def each_loaded(record, &block)
      target = resolve(record)

      block.call(target) unless target.nil?
    end

    # singular targets are denormalized inline, not in batches
    def async_relation(record) = nil
  end

  ##
  # Association::Collection is a direct collection association, e.g. a
  # has_many.
  class Association::Collection < Association::Direct
    def each_loaded(record, &block) = resolve(record).each(&block)

    def async_relation(record) = resolve(record)
  end

  ##
  # Association::Through is an association resolved via a method on the
  # :through association's record, e.g. a role through a polymorphic bearer,
  # so an unpersisted :through record is supported. subclasses implement the
  # arity of the resolved records.
  class Association::Through < Association
    # the :through association's name, i.e. our reflection is the :through
    # association, not the resolved association itself
    def through = reflection.name

    def owner(record)   = record.public_send(through)
    def resolve(record) = owner(record)&.public_send(name)
  end

  ##
  # Association::Through::Singular is a singular association resolved through
  # another, e.g. a role through a polymorphic bearer.
  class Association::Through::Singular < Association::Through
    def each_loaded(record, &block)
      target = resolve(record)

      block.call(target) unless target.nil?
    end

    # singular targets are denormalized inline, not in batches
    def async_relation(record) = nil
  end

  ##
  # Association::Through::Collection is a collection association resolved
  # through another, e.g. tokens through a role's resource. records are
  # scoped to those owned by the :through record (see owner_reflection). use
  # :inverse_of to explicitly name the owner association when the resolved
  # relation's inverse is not the ownership edge.
  class Association::Through::Collection < Association::Through
    def initialize(model, name, inverse_of: nil, **)
      super(model, name, **)

      @inverse_of = inverse_of
    end

    # each_loaded only yields records already in memory -- any writes are
    # never saved, so loading the entire collection just to write attributes
    # on discarded copies would be wasted work (persisted records are
    # denormalized via async_relation and the records' own denormalization
    # callbacks)
    def each_loaded(record, &block)
      owner    = owner(record)
      relation = resolve(record)
      return unless
        relation&.loaded?

      reflection = owner_reflection(owner)

      relation.each do |target|
        block.call(target) if owned_by?(target, owner, reflection)
      end
    end

    def async_relation(record)
      owner    = owner(record)
      relation = resolve(record)
      return if
        relation.nil?

      # explicitly scope the relation to records owned by the :through record
      relation.where(owner_reflection(owner).name => owner)
    end

    private

    # owner_reflection reflects on the resolved records' owner association,
    # i.e. their belongs_to association that points back at the :through
    # record, e.g. tokens are owned by their polymorphic bearer. resolved via
    # an explicit :inverse_of when given, otherwise via the inverse of the
    # :through record's association. an explicit :inverse_of is required when
    # the relation's inverse is not the ownership edge, e.g. an environment's
    # tokens are scoped to the environment, not to the environment as a
    # bearer.
    def owner_reflection(owner)
      reflection = owner.class.reflect_on_association(name)
      raise AssociationNotFoundError, "no association found on #{owner.class} for #{name.inspect}" if
        reflection.nil?

      if @inverse_of.present?
        reflection.klass.reflect_on_association(@inverse_of) or
          raise InverseAssociationNotFoundError, "no inverse association found on #{reflection.klass} for #{@inverse_of.inspect}"
      else
        reflection.inverse_of or
          raise InverseAssociationNotFoundError, "no inverse association found on #{owner.class} for #{name.inspect}"
      end
    end

    # owned_by? returns true when the record's owner association foreign keys
    # match the owner.
    def owned_by?(record, owner, owner_reflection)
      return false if
        owner.nil?

      owned   = record.read_attribute(owner_reflection.foreign_key)  == owner.read_attribute(owner.class.primary_key)
      owned &&= record.read_attribute(owner_reflection.foreign_type) == owner.class.polymorphic_name if
        owner_reflection.polymorphic?

      owned
    end
  end

  ##
  # Denormalization is a single denormalized attribute declaration, i.e. one
  # attribute of one denormalizes call. subclasses implement the direction:
  # From copies a source record's attribute onto the declaring model, and To
  # copies the declaring model's attribute onto target records. the records
  # themselves are resolved by the denormalization's association.
  #
  # callbacks registered by instrument! close over the denormalization and
  # receive the record, so no methods are defined on the including model.
  class Denormalization
    attr_reader :model, :attribute, :association, :column

    def initialize(model, attribute:, association:, prefix: nil, as: nil)
      @model       = model
      @attribute   = attribute
      @association = association
      @column      = column_name(prefix:, as:)
    end

    # key is the name the denormalization is registered under.
    def key = raise NotImplementedError

    # instrument! registers the denormalization's callbacks on the model.
    def instrument! = raise NotImplementedError

    private

    def column_name(prefix:, as:)
      case
      when as.present?
        as.to_s
      when prefix == true
        "#{association.name}_#{attribute}"
      when (prefix in Symbol | String)
        "#{prefix}_#{attribute}"
      else
        attribute.to_s
      end
    end

    # find_reflection_by_foreign_key returns the record's association backed
    # by the given foreign key column, if any, e.g. :policy for policy_id.
    def find_reflection_by_foreign_key(record_class, column_name)
      record_class.reflect_on_all_associations.find { it.foreign_key == column_name.to_s }
    end
  end

  ##
  # Denormalization::From denormalizes an attribute from a source record onto
  # the declaring model, e.g. a token copies its bearer's role name into
  # bearer_role.
  class Denormalization::From < Denormalization
    def key = column.to_sym

    def instrument!
      raise ArgumentError, "must be a singular association: #{association.name.inspect}" if
        association.collection?

      denormalization = self
      source_changed  = association.changed_condition

      # FIXME(ezekg) after_initialize ignores prepend: false
      model.set_callback :initialize, :after, -> record { denormalization.denormalize(record) }, if: source_changed, unless: :persisted?, prepend: false
      model.before_validation -> record { denormalization.denormalize(record) }, if: source_changed, on: :create
      model.before_update -> record { denormalization.denormalize(record, persisted: true) }, if: source_changed

      # make sure validation fails if our denormalized column is modified directly
      model.validate -> record { denormalization.validate(record) }, if: :"#{column}_changed?", on: :update
    end

    # denormalize copies the source record's attribute onto the record. when
    # the source is unpersisted, i.e. persisted is false and the resolved
    # record is not saved, foreign keys are copied by assigning the
    # association.
    def denormalize(record, persisted: false)
      source = association.resolve(record)

      if persisted || source&.persisted?
        denormalize_persisted(record, source)
      else
        denormalize_unpersisted(record, source)
      end
    end

    def validate(record)
      source = association.resolve(record)

      unless record.read_attribute(column) == source&.read_attribute(attribute)
        if reflection = find_reflection_by_foreign_key(record.class, column)
          record.errors.add reflection.name, :not_allowed, message: 'cannot be modified directly because it is a denormalized association'
        else
          record.errors.add column.to_sym, :not_allowed, message: 'cannot be modified directly because it is a denormalized attribute'
        end
      end
    end

    private

    def denormalize_persisted(record, source) = record.write_attribute(column, source&.read_attribute(attribute))
    def denormalize_unpersisted(record, source)
      # NB(ezekg) if we're denormalizing a foreign key, we need to look up the association
      #           and denormalize the actual record, since it likely doesn't have a
      #           primary key assigned yet.
      if source.present? && (source_reflection = find_reflection_by_foreign_key(source.class, attribute))
        target_reflection = find_reflection_by_foreign_key(record.class, column)

        record.public_send(:"#{target_reflection.name}=", source.public_send(source_reflection.name))
      else
        record.write_attribute(column, source&.read_attribute(attribute))
      end
    end
  end

  ##
  # Denormalization::To denormalizes an attribute from the declaring model
  # onto target records, e.g. a role copies its name onto its resource's
  # tokens. targets already in memory are denormalized synchronously, and
  # persisted targets are denormalized after save -- asynchronously in
  # batches for relations, inline for singular targets.
  class Denormalization::To < Denormalization
    def key = attribute

    def instrument!
      denormalization = self

      # FIXME(ezekg) set to nil on destroy unless the association is dependent?
      model.after_initialize -> record { denormalization.denormalize(record) }, if: :"#{attribute}_changed?", unless: :persisted?
      model.before_validation -> record { denormalization.denormalize(record) }, if: :"#{attribute}_changed?", on: :create
      model.after_save -> record { denormalization.denormalize(record, persisted: true) }, if: :"#{attribute}_previously_changed?"
    end

    # denormalize writes the attribute onto target records: loaded, in-memory
    # targets before save, persisted targets after save.
    def denormalize(record, persisted: false)
      if persisted
        denormalize_persisted(record)
      else
        denormalize_loaded(record)
      end
    end

    private

    # denormalize_loaded writes the attribute onto loaded, in-memory target
    # records.
    def denormalize_loaded(record)
      value = record.read_attribute(attribute)

      association.each_loaded(record) do |target|
        target.write_attribute(column, value)
      end
    end

    # denormalize_persisted writes the attribute onto persisted target
    # records -- asynchronously in batches for collection targets, inline
    # for singular targets.
    def denormalize_persisted(record)
      if relation = association.async_relation(record)
        denormalize_association_async(record, relation)
      else
        denormalize_association(record)
      end
    end

    def denormalize_association_async(record, relation)
      options = {}

      # NB(ezekg) on create there's no previous value to guard against lost
      #           updates, and targets may carry stale values, e.g. from a
      #           previously destroyed source, so we skip the filter
      options[:source_attribute_value_was] = record.public_send(:"#{attribute}_previously_was") unless
        record.previously_new_record?

      relation.ids.each_slice(DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE) do |ids|
        DenormalizeAssociationAsyncJob.perform_later(
          source_class_name: record.class.name,
          source_id: record.id,
          source_attribute_name: attribute,
          target_class_name: relation.klass.name,
          target_ids: ids,
          target_attribute_name: column,
          **options,
        )
      end
    end

    def denormalize_association(record)
      target = association.resolve(record)

      target&.update(column => record.read_attribute(attribute))
    end
  end

  class DenormalizeAssociationAsyncJob < ActiveJob::Base
    NOT_PROVIDED = Class.new

    # NB(ezekg) we're enqueued from after_save, i.e. inside the transaction, so
    #           we need to defer the enqueue until after commit, otherwise the
    #           job may run before the source's new value is committed and
    #           no-op, leaving the denormalized attribute stale
    self.enqueue_after_transaction_commit = true

    queue_as { ActiveRecord.queues[:denormalize] }

    discard_on ActiveJob::DeserializationError

    def perform(
      source_class_name:,
      source_id:,
      source_attribute_name:,
      source_attribute_value_was: NOT_PROVIDED,
      target_class_name:,
      target_ids:,
      target_attribute_name:
    )
      source_class = source_class_name.constantize
      source       = source_class.find_by(source_class.primary_key.to_sym => source_id)

      unless source.nil?
        target_class = target_class_name.constantize
        target       = target_class.where(target_class.primary_key.to_sym => target_ids)

        unless source_attribute_value_was == NOT_PROVIDED
          target = target.where(target_attribute_name => source_attribute_value_was)
        end

        target.update_all(
          target_attribute_name => source.read_attribute(source_attribute_name),
        )
      end
    end
  end
end
