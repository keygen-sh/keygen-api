# frozen_string_literal: true

module Denormalizable
  extend ActiveSupport::Concern

  DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE = 1_000

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
                            Denormalization::Pull.new(self, attribute: attribute_name, source: from, through:, prefix:, as:)
                          else
                            Denormalization::Push.new(self, attribute: attribute_name, target: to, through:, inverse_of:, prefix:, as:)
                          end

        denormalization.instrument!

        self.denormalizations = denormalizations.merge(denormalization.key => denormalization.freeze)
      end
    end

    def denormalized_attributes = denormalizations.keys.to_set
  end

  ##
  # Denormalization is a single denormalized attribute declaration, i.e. one
  # attribute of one denormalizes call. Subclasses implement the direction:
  # Pull writes a source record's attribute onto the declaring model, and
  # Push writes the declaring model's attribute onto target records.
  #
  # Callbacks registered by instrument! close over the denormalization and
  # receive the record, so no methods are defined on the including model.
  class Denormalization
    attr_reader :model, :attribute, :through, :column

    def initialize(model, attribute:, through: nil, prefix: nil, as: nil)
      @model     = model
      @attribute = attribute
      @through   = through
      @prefix    = prefix
      @as        = as
    end

    def through? = through.present?

    private

    def column_name_for(association_name)
      case
      when @as.present?
        @as.to_s
      when @prefix == true
        "#{association_name}_#{attribute}"
      when (@prefix in Symbol | String)
        "#{@prefix}_#{attribute}"
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
  # Pull denormalizes an attribute from a source record onto the declaring
  # model, e.g. a token pulls its bearer's role name into bearer_role. The
  # source is resolved via a path of methods, so a :through source, e.g. a
  # role through a polymorphic bearer, supports unpersisted records.
  class Denormalization::Pull < Denormalization
    def initialize(model, attribute:, source:, through: nil, prefix: nil, as: nil)
      super(model, attribute:, through:, prefix:, as:)

      @source = source
      @path   = [through, source].compact
      @column = column_name_for(source)
    end

    def key = column.to_sym

    def instrument!
      reflection = model.reflect_on_association(@path.first)
      raise ArgumentError, "invalid #{through? ? ':through' : ':from'} association: #{@path.first.inspect}" if
        reflection.nil?

      raise ArgumentError, "must be a singular association: #{@path.first.inspect}" if
        reflection.collection?

      denormalization = self
      source_changed  = source_changed_condition(reflection)

      # FIXME(ezekg) after_initialize ignores prepend: false
      model.set_callback :initialize, :after, -> { denormalization.write(self) }, if: source_changed, unless: :persisted?, prepend: false
      model.before_validation -> { denormalization.write(self) }, if: source_changed, on: :create
      model.before_update -> { denormalization.write(self, persisted: true) }, if: source_changed

      # make sure validation fails if our denormalized column is modified directly
      model.validate -> { denormalization.validate(self) }, if: :"#{column}_changed?", on: :update
    end

    # write copies the source record's attribute onto the record. when the
    # source is unpersisted, i.e. persisted is false and the resolved record
    # is not saved, foreign keys are copied by assigning the association.
    def write(record, persisted: false)
      source = resolve(record)

      if persisted || source&.persisted?
        record.write_attribute(column, source&.read_attribute(attribute))
      else
        write_unpersisted(record, source)
      end
    end

    def validate(record)
      source = resolve(record)

      unless record.read_attribute(column) == source&.read_attribute(attribute)
        if reflection = find_reflection_by_foreign_key(record.class, column)
          record.errors.add reflection.name, :not_allowed, message: 'cannot be modified directly because it is a denormalized association'
        else
          record.errors.add column.to_sym, :not_allowed, message: 'cannot be modified directly because it is a denormalized attribute'
        end
      end
    end

    private

    def resolve(record) = @path.reduce(record) { |r, step| r&.public_send(step) }

    def write_unpersisted(record, source)
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

    # source_changed_condition returns a callable condition that returns true
    # when the source association has changed, via its foreign keys or target
    # record. for a :through source, the :through association is watched.
    def source_changed_condition(reflection)
      foreign_keys  = Array(reflection.foreign_key)
      foreign_keys += [reflection.foreign_type] if reflection.polymorphic?

      -> { foreign_keys.any? { send(:"#{it}_changed?") } || send(:"#{reflection.name}_changed?") }
    end
  end

  ##
  # Push denormalizes an attribute from the declaring model onto target
  # records, e.g. a role pushes its name onto its resource's tokens. targets
  # already in memory are synced directly, and persisted targets are synced
  # asynchronously in batches after save.
  #
  # for a :through target, the relation is resolved via a method on the
  # :through association's record and explicitly scoped to records owned by
  # it (see owner_reflection). use :inverse_of to explicitly name the
  # target's owner association when the target relation's inverse is not the
  # ownership edge.
  class Denormalization::Push < Denormalization
    def initialize(model, attribute:, target:, through: nil, inverse_of: nil, prefix: nil, as: nil)
      super(model, attribute:, through:, prefix:, as:)

      @target     = target
      @inverse_of = inverse_of
      @column     = column_name_for(target)
    end

    def key = attribute

    def instrument!
      if through?
        reflection = model.reflect_on_association(through)
        raise ArgumentError, "invalid :through association: #{through.inspect}" if
          reflection.nil?

        raise ArgumentError, "must be a singular association: #{through.inspect}" if
          reflection.collection?
      else
        @reflection = model.reflect_on_association(@target)
        raise ArgumentError, "invalid :to association: #{@target.inspect}" if
          @reflection.nil?
      end

      denormalization = self

      # FIXME(ezekg) set to nil on destroy unless the association is dependent?
      model.after_initialize -> { denormalization.sync(self) }, if: :"#{attribute}_changed?", unless: :persisted?
      model.before_validation -> { denormalization.sync(self) }, if: :"#{attribute}_changed?", on: :create
      model.after_save -> { denormalization.sync_persisted(self) }, if: :"#{attribute}_previously_changed?"
    end

    # sync writes the record's attribute onto in-memory target records. any
    # writes are never saved, so for a :through target only records already
    # in memory are synced -- loading the entire collection just to write
    # attributes on discarded copies would be wasted work (persisted records
    # are kept in sync via sync_persisted and the target's own denormalization
    # callbacks).
    def sync(record)
      value = record.read_attribute(attribute)

      case
      when through?
        owner    = record.public_send(through)
        relation = owner&.public_send(@target)
        return unless
          relation&.loaded?

        reflection = owner_reflection(owner)

        relation.each do |target|
          next unless
            owned_by?(target, owner, reflection)

          target.write_attribute(column, value)
        end
      when collection?
        record.public_send(@target).each { it.write_attribute(column, value) }
      else
        record.public_send(@target)&.write_attribute(column, value)
      end
    end

    # sync_persisted writes the record's attribute onto persisted target
    # records, asynchronously in batches for relations.
    def sync_persisted(record)
      case
      when through?
        owner    = record.public_send(through)
        relation = owner&.public_send(@target)
        return if
          relation.nil?

        # explicitly scope the relation to records owned by the :through record
        reflection = owner_reflection(owner)

        enqueue(record, relation.where(reflection.name => owner))
      when collection?
        enqueue(record, record.public_send(@target))
      else
        target = record.public_send(@target)

        target&.update(column => record.read_attribute(attribute))
      end
    end

    private

    def collection? = @reflection.collection?

    def enqueue(record, target_relation)
      options = {}

      # NB(ezekg) on create there's no previous value to guard against lost
      #           updates, and targets may carry stale values, e.g. from a
      #           previously destroyed source, so we skip the filter
      options[:source_attribute_value_was] = record.public_send(:"#{attribute}_previously_was") unless
        record.previously_new_record?

      target_relation.ids.each_slice(DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE) do |ids|
        DenormalizeAssociationAsyncJob.perform_later(
          source_class_name: record.class.name,
          source_id: record.id,
          source_attribute_name: attribute,
          target_class_name: target_relation.klass.name,
          target_ids: ids,
          target_attribute_name: column,
          **options,
        )
      end
    end

    # owner_reflection reflects on the target's owner association, i.e. the
    # target's belongs_to association that points back at the :through record,
    # e.g. tokens are owned by their polymorphic bearer. resolved via an
    # explicit :inverse_of when given, otherwise via the inverse of the
    # :through record's association to the target. an explicit :inverse_of is
    # required when the target relation's inverse is not the ownership edge,
    # e.g. an environment's tokens are scoped to the environment, not to the
    # environment as a bearer.
    def owner_reflection(owner)
      reflection = owner.class.reflect_on_association(@target)
      raise ArgumentError, "no association found on #{owner.class} for #{@target.inspect}" if
        reflection.nil?

      if @inverse_of.present?
        reflection.klass.reflect_on_association(@inverse_of) or
          raise ArgumentError, "no inverse association found on #{reflection.klass} for #{@inverse_of.inspect}"
      else
        reflection.inverse_of or
          raise ArgumentError, "no inverse association found on #{owner.class} for #{@target.inspect}"
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
      source_attribute_value_was: NOT_PROVIDED, # FIXME(ezekg) remove once old jobs are processed
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
