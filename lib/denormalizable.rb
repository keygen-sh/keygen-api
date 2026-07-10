# frozen_string_literal: true

module Denormalizable
  class Error < StandardError; end
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
      def denormalizes(*attribute_names, from: nil, to: nil, through: nil, inverse_of: nil, prefix: nil, as: nil)
        raise ArgumentError, 'must provide either :from or :to (but not both)' unless
          from.present? ^ to.present?

        raise ArgumentError, 'must provide :to and :through when using :inverse_of' if
          inverse_of.present? && (to.blank? || through.blank?)

        raise ArgumentError, 'must provide either :prefix or :as (but not both)' if
          prefix.present? && as.present?

        raise ArgumentError, 'must provide a single attribute when using :as' if
          as.present? && attribute_names.many?

        attribute_names.each do |attribute_name|
          denormalization = if from.present?
                              association = Association.build(self, from, kind: :from, through:)

                              Denormalization::From.new(self, attribute: attribute_name, association:, prefix:, as:)
                            else
                              association = Association.build(self, to, kind: :to, through:, inverse_of:)

                              Denormalization::To.new(self, attribute: attribute_name, association:, prefix:, as:)
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
  #
  # subclasses implement the resolution interface -- resolve, each_loaded and
  # async_relation. Direct associations are declared on the model itself and
  # split into Singular and Collection at declaration time, while Through
  # associations are resolved via the :through record, with arity determined
  # at runtime (see Association.build).
  class Association
    class << self
      # build returns the association for the given name: a Singular or
      # Collection for an association declared on the model itself, or a
      # Through when the records are resolved via a method on the :through
      # association's record.
      def build(model, name, kind:, through: nil, inverse_of: nil)
        if through.present?
          build_through_association(model, name, kind:, through:, inverse_of:)
        else
          build_association(model, name, kind:, inverse_of:)
        end
      end

      private

      # NB(ezekg) unlike the direct builder below, we can't split a Through
      #           into singular/collection variants at declaration time: the
      #           resolved records live on the :through record's class, and
      #           for a polymorphic :through there is no class to reflect on
      #           until we have a record in hand -- so Through resolves the
      #           records' arity at runtime, per-owner, instead
      def build_through_association(model, name, kind:, through:, inverse_of:)
        reflection = model.reflect_on_association(through)
        raise ArgumentError, "invalid :through association: #{through.inspect}" if
          reflection.nil?

        # NB(ezekg) unlike the resolved records, the :through association is
        #           declared on the model itself, so it's always reflectable
        #           here -- and it must be singular, since records are
        #           resolved via a single :through record, e.g. fanning out
        #           through a collection is not supported
        raise ArgumentError, "must be a singular :through association: #{through.inspect}" if
          reflection.collection?

        Through.new(model, name, reflection:, inverse_of:)
      end

      def build_association(model, name, kind:, inverse_of:)
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

    attr_reader :model, :name, :reflection

    def initialize(model, name, reflection:)
      @model      = model
      @name       = name
      @reflection = reflection
    end

    # resolve returns the resolved source or target record(s) for the given
    # record.
    def resolve(record) = raise NotImplementedError

    # each_loaded yields the resolved records already in memory, for
    # denormalizing without loading the full collection.
    def each_loaded(record, &block) = raise NotImplementedError

    # async_relation returns the resolved records as a batchable relation, or
    # nil when the records don't resolve to a persisted collection, i.e.
    # singular targets are denormalized inline instead.
    def async_relation(record) = raise NotImplementedError

    # async? returns true when the resolved records denormalize
    # asynchronously, i.e. they resolve to a batchable relation.
    def async?(record) = !async_relation(record).nil?

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
  # so an unpersisted :through record is supported. collection records are
  # scoped to those owned by the :through record (see owner_reflection_for). use
  # :inverse_of to explicitly name the owner association when the resolved
  # relation's inverse is not the ownership edge.
  #
  # NB(ezekg) unlike Direct's declaration-time Singular/Collection split, the
  #           resolved records' arity is resolved at runtime, per-owner, since
  #           a polymorphic :through has no class to reflect on until we have
  #           a record in hand (see Association.build).
  class Association::Through < Association
    def initialize(model, name, inverse_of: nil, **)
      super(model, name, **)

      @inverse_of = inverse_of
    end

    # the :through association's name, i.e. our reflection is the :through
    # association, not the resolved association itself
    def through = reflection.name

    def owner(record)   = record.public_send(through)
    def resolve(record) = owner(record)&.public_send(name)

    # each_loaded yields the resolved records for in-memory denormalization.
    # collection writes are never saved, so only loaded records are yielded
    # there -- loading the entire collection just to write attributes on
    # discarded copies would be wasted work (persisted records are
    # denormalized via async_relation and the records' own denormalization
    # callbacks)
    def each_loaded(record, &block)
      owner  = owner(record)
      target = resolve(record)
      return if
        target.nil?

      if reflection = collection_reflection_for(owner)
        return unless
          target.loaded?

        owner_reflection = owner_reflection_for(owner, reflection)

        target.each do |owned|
          block.call(owned) if owned_by?(owned, owner, owner_reflection)
        end
      else
        block.call(target)
      end
    end

    def async_relation(record)
      owner  = owner(record)
      target = resolve(record)
      return if
        target.nil?

      # singular targets are denormalized inline, not in batches
      reflection = collection_reflection_for(owner)
      return if
        reflection.nil?

      # explicitly scope the relation to records owned by the :through record
      target.where(owner_reflection_for(owner, reflection).name => owner)
    end

    private

    # collection_reflection_for returns the resolved association's reflection
    # on the owner's class when it's a collection, otherwise nil, e.g. for
    # singular associations and unreflectable names like plain methods
    def collection_reflection_for(owner)
      reflection = owner.class.reflect_on_association(name)

      reflection if reflection&.collection?
    end

    # owner_reflection_for reflects on the resolved records' owner association,
    # i.e. their belongs_to association that points back at the :through
    # record, e.g. tokens are owned by their polymorphic bearer. resolved via
    # an explicit :inverse_of when given, otherwise via the inverse of the
    # :through record's association. an explicit :inverse_of is required when
    # the relation's inverse is not the ownership edge, e.g. an environment's
    # tokens are scoped to the environment, not to the environment as a
    # bearer.
    def owner_reflection_for(owner, reflection)
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

      # NB(ezekg) change tracking via changed_condition relies on the watched
      #           reflection's foreign keys and <name>_changed? living on the
      #           declaring model, which is only the case for a belongs_to --
      #           for a has_one, both live on the other side
      raise ArgumentError, "must be a belongs_to association: #{association.reflection.name.inspect}" unless
        association.reflection.belongs_to?

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
      source = resolve_source(record)

      if persisted || source&.persisted?
        denormalize_persisted(record, source)
      else
        denormalize_unpersisted(record, source)
      end
    end

    def validate(record)
      source = resolve_source(record)

      unless record.read_attribute(column) == source&.read_attribute(attribute)
        if reflection = find_reflection_by_foreign_key(record.class, column)
          record.errors.add reflection.name, :not_allowed, message: 'cannot be modified directly because it is a denormalized association'
        else
          record.errors.add column.to_sym, :not_allowed, message: 'cannot be modified directly because it is a denormalized attribute'
        end
      end
    end

    private

    # resolve_source resolves the source record, guarding against a source
    # that resolves to a collection at runtime, e.g. via a polymorphic
    # :through, whose arity can't be reflected on at declaration time (see
    # Association.build)
    def resolve_source(record)
      source = association.resolve(record)
      raise Error, "cannot denormalize from a collection: #{association.name.inspect}" if
        source.is_a?(ActiveRecord::Relation)

      source
    end

    def denormalize_persisted(record, source) = record.write_attribute(column, source&.read_attribute(attribute))
    def denormalize_unpersisted(record, source)
      # NB(ezekg) if we're denormalizing a foreign key into an association-backed
      #           column, we need to look up the association and denormalize the
      #           actual record, since it likely doesn't have a primary key
      #           assigned yet -- otherwise fall back to a plain write, matching
      #           the persisted path
      if source.present? && (source_reflection = find_reflection_by_foreign_key(source.class, attribute)) && (target_reflection = find_reflection_by_foreign_key(record.class, column))
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
    # NB(ezekg) unlike From, which owns its column and can key by it, the
    #           denormalized column lives on the targets here -- so we key by
    #           target and attribute, since the same attribute may be
    #           denormalized to multiple targets
    def key = :"#{association.name}.#{attribute}"

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
      if association.async?(record)
        denormalize_association_async(record)
      else
        denormalize_association(record)
      end
    end

    def denormalize_association_async(record)
      DenormalizeAsyncJob.perform_later(
        source_class_name: record.class.name,
        source_id: record.id,
        denormalization_key: key.to_s,
      )
    end

    def denormalize_association(record)
      target = association.resolve(record)

      target&.update_column(column, record.read_attribute(attribute))
    end
  end

  ##
  # DenormalizeAsyncJob denormalizes a source record's attribute onto its
  # current targets, i.e. it makes the targets match the source. the target
  # relation is derived at perform-time, not enqueue-time, so targets created
  # or reassigned while the job was queued are resolved correctly -- and
  # performing the same job any number of times is safe, since it always
  # converges on the source's current committed value.
  class DenormalizeAsyncJob < ActiveJob::Base
    # NB(ezekg) we're enqueued from after_save, i.e. inside the transaction, so
    #           we need to defer the enqueue until after commit, otherwise the
    #           job may run before the source's new value is committed and
    #           denormalize a stale value
    self.enqueue_after_transaction_commit = true

    queue_as { ActiveRecord.queues[:denormalize] }

    def perform(source_class_name:, source_id:, denormalization_key:)
      source_class    = source_class_name.constantize
      denormalization = source_class.denormalizations.fetch(denormalization_key.to_sym)
      primary_key     = source_class.primary_key

      source = source_class.find_by(primary_key => source_id)
      return if
        source.nil?

      relation = denormalization.association.async_relation(source)
      return if
        relation.nil?

      attribute = denormalization.attribute
      column    = denormalization.column

      # cursor on insertion order since primary keys are not necessarily
      # k-sortable, e.g. UUIDv4 -- records inserted mid-enumeration land
      # ahead of the cursor instead of being skipped behind it
      relation.in_batches(of: DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE, cursor: %i[created_at id]) do |batch|
        source_class.transaction do
          # NB(ezekg) FOR SHARE pins the source's latest committed value until
          #           the batch commits, i.e. what we read is what we write,
          #           and concurrent jobs can only ever write the same value
          id, value = source_class.where(primary_key => source_id)
                                  .lock('FOR SHARE')
                                  .pick(
                                    primary_key,
                                    attribute,
                                  )

          # source was deleted mid-run
          return if
            id.nil?

          batch.update_all(column => value)
        end
      end
    end
  end

  # FIXME(ezekg) superseded by DenormalizeAsyncJob -- remove after the queue
  #              drains, since jobs enqueued with these args may be in-flight
  class DenormalizeAssociationAsyncJob < ActiveJob::Base
    NOT_PROVIDED = Class.new

    # NB(ezekg) we're enqueued from after_save, i.e. inside the transaction, so
    #           we need to defer the enqueue until after commit, otherwise the
    #           job may run before the source's new value is committed and
    #           no-op, leaving the denormalized attribute stale
    self.enqueue_after_transaction_commit = true

    queue_as { ActiveRecord.queues[:denormalize] }

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
