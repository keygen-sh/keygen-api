# frozen_string_literal: true

module Denormalizable
  extend ActiveSupport::Concern

  DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE = 1_000

  class_methods do
    def denormalizes(*attribute_names, from: nil, to: nil, through: nil, prefix: nil, as: nil)
      raise ArgumentError, 'must provide either :from or :to (but not both)' unless
        from.present? ^ to.present?

      raise ArgumentError, 'must provide either :prefix or :as (but not both)' if
        prefix.present? && as.present?

      raise ArgumentError, 'must provide a single attribute when using :as' if
        as.present? && attribute_names.many?

      case
      when from.present? && through.present?
        attribute_names.each { instrument_denormalized_attribute_from_through(it, from:, through:, prefix:, as:) }
      when from.present?
        attribute_names.each { instrument_denormalized_attribute_from(it, from:, prefix:, as:) }
      when to.present? && through.present?
        attribute_names.each { instrument_denormalized_attribute_to_through(it, to:, through:, prefix:, as:) }
      when to.present?
        attribute_names.each { instrument_denormalized_attribute_to(it, to:, prefix:, as:) }
      end
    end

    private

    def instrument_denormalized_attribute_from(attribute_name, from:, prefix:, as: nil)
      case from
      in Symbol => association_name if reflection = reflect_on_association(association_name)
        prefixed_attribute_name = denormalized_attribute_name(association_name, attribute_name, prefix:, as:)

        if reflection.collection?
          raise ArgumentError, "must be a singular association: #{association_name.inspect}"
        end

        association_changed = denormalized_association_changed(reflection)

        # FIXME(ezekg) after_initialize ignores prepend: false
        set_callback :initialize, :after, -> { write_denormalized_attribute_from_schrodingers_record(association_name, attribute_name, prefixed_attribute_name) }, if: association_changed, unless: :persisted?, prepend: false
        before_validation -> { write_denormalized_attribute_from_schrodingers_record(association_name, attribute_name, prefixed_attribute_name) }, if: association_changed, on: :create
        before_update -> { write_denormalized_attribute_from_persisted_record(association_name, attribute_name, prefixed_attribute_name) }, if: association_changed

        # make sure validation fails if our denormalized column is modified directly
        validate -> { validate_denormalized_attribute_from_persisted_record(association_name, attribute_name, prefixed_attribute_name) }, if: :"#{prefixed_attribute_name}_changed?", on: :update

        denormalized_attributes << prefixed_attribute_name.to_sym
      else
        raise ArgumentError, "invalid :from association: #{from.inspect}"
      end
    end

    # instrument_denormalized_attribute_from_through instruments a denormalized attribute
    # where the source record is resolved in-memory via a method on the :through
    # association's record, e.g. a role through a polymorphic bearer, so an
    # unpersisted :through record is supported.
    def instrument_denormalized_attribute_from_through(attribute_name, from:, through:, prefix:, as: nil)
      case through
      in Symbol => through_association_name if reflection = reflect_on_association(through_association_name)
        prefixed_attribute_name = denormalized_attribute_name(from, attribute_name, prefix:, as:)

        if reflection.collection?
          raise ArgumentError, "must be a singular association: #{through_association_name.inspect}"
        end

        association_changed = denormalized_association_changed(reflection)

        set_callback :initialize, :after, -> { write_denormalized_attribute_from_record_through(through_association_name, from, attribute_name, prefixed_attribute_name) }, if: association_changed, unless: :persisted?, prepend: false
        before_validation -> { write_denormalized_attribute_from_record_through(through_association_name, from, attribute_name, prefixed_attribute_name) }, if: association_changed, on: :create
        before_update -> { write_denormalized_attribute_from_record_through(through_association_name, from, attribute_name, prefixed_attribute_name) }, if: association_changed

        validate -> { validate_denormalized_attribute_from_record_through(through_association_name, from, attribute_name, prefixed_attribute_name) }, if: :"#{prefixed_attribute_name}_changed?", on: :update

        denormalized_attributes << prefixed_attribute_name.to_sym
      else
        raise ArgumentError, "invalid :through association: #{through.inspect}"
      end
    end

    def instrument_denormalized_attribute_to(attribute_name, to:, prefix:, as: nil)
      case to
      in Symbol => association_name if reflection = reflect_on_association(association_name)
        prefixed_attribute_name = denormalized_attribute_name(association_name, attribute_name, prefix:, as:)

        # FIXME(ezekg) set to nil on destroy unless the association is dependent?
        if reflection.collection?
          after_initialize -> { write_denormalized_attribute_to_unpersisted_relation(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", unless: :persisted?
          before_validation -> { write_denormalized_attribute_to_unpersisted_relation(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", on: :create
          after_update -> { write_denormalized_attribute_to_persisted_relation(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_previously_changed?"
        else
          after_initialize -> { write_denormalized_attribute_to_unpersisted_record(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", unless: :persisted?
          before_validation -> { write_denormalized_attribute_to_unpersisted_record(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", on: :create
          after_update -> { write_denormalized_attribute_to_persisted_record(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_previously_changed?"
        end

        denormalized_attributes << attribute_name
      else
        raise ArgumentError, "invalid :to association: #{to.inspect}"
      end
    end

    # instrument_denormalized_attribute_to_through instruments a denormalized attribute
    # where the target relation is resolved via a method on the :through association's
    # record, scoped to records owned by it (see denormalized_owner_reflection_through),
    # e.g. denormalizing a role's name to tokens through the role's resource.
    def instrument_denormalized_attribute_to_through(attribute_name, to:, through:, prefix:, as: nil)
      case through
      in Symbol => through_association_name if reflection = reflect_on_association(through_association_name)
        prefixed_attribute_name = denormalized_attribute_name(to, attribute_name, prefix:, as:)

        if reflection.collection?
          raise ArgumentError, "must be a singular association: #{through_association_name.inspect}"
        end

        after_initialize -> { write_denormalized_attribute_to_unpersisted_relation_through(through_association_name, to, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", unless: :persisted?
        before_validation -> { write_denormalized_attribute_to_unpersisted_relation_through(through_association_name, to, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", on: :create
        after_update -> { write_denormalized_attribute_to_persisted_relation_through(through_association_name, to, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_previously_changed?"

        denormalized_attributes << attribute_name
      else
        raise ArgumentError, "invalid :through association: #{through.inspect}"
      end
    end

    def denormalized_attribute_name(association_name, attribute_name, prefix: nil, as: nil)
      case
      when as.present?
        as.to_s
      when prefix == true
        "#{association_name}_#{attribute_name}"
      when (prefix in Symbol | String)
        "#{prefix}_#{attribute_name}"
      else
        attribute_name.to_s
      end
    end

    # denormalized_association_changed returns a callable condition that returns true
    # when the given association has changed, via its foreign keys or target record.
    def denormalized_association_changed(reflection)
      foreign_keys  = Array(reflection.foreign_key)
      foreign_keys += [reflection.foreign_type] if reflection.polymorphic?

      -> { foreign_keys.any? { send(:"#{it}_changed?") } || send(:"#{reflection.name}_changed?") }
    end
  end

  # FIXME(ezekg) move this out into a separate module so that we don't pollute the model
  included do
    cattr_reader :denormalized_attributes, default: Set.new

    private

    def write_denormalized_attribute_to_unpersisted_relation(target_association_name, target_attribute_name, source_attribute_name)
      relation = send(target_association_name)

      relation.each do |record|
        record.write_attribute(target_attribute_name, read_attribute(source_attribute_name))
      end
    end

    def write_denormalized_attribute_to_persisted_relation(target_association_name, target_attribute_name, source_attribute_name)
      source_attribute_value_was = send("#{source_attribute_name}_previously_was")
      target_association         = send(target_association_name)

      target_association.ids.each_slice(DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE) do |ids|
        DenormalizeAssociationAsyncJob.perform_later(
          source_class_name: self.class.name,
          source_id: id,
          source_attribute_name:,
          source_attribute_value_was:,
          target_class_name: target_association.klass.name,
          target_ids: ids,
          target_attribute_name:,
        )
      end
    end

    def write_denormalized_attribute_to_unpersisted_relation_through(through_association_name, target_name, target_attribute_name, source_attribute_name)
      owner    = send(through_association_name)
      relation = owner&.send(target_name)
      return if
        relation.nil?

      reflection = denormalized_owner_reflection_through(through_association_name, relation.klass)

      relation.each do |record|
        next unless
          denormalized_record_owned_by?(record, owner, reflection)

        record.write_attribute(target_attribute_name, read_attribute(source_attribute_name))
      end
    end

    def write_denormalized_attribute_to_persisted_relation_through(through_association_name, target_name, target_attribute_name, source_attribute_name)
      owner    = send(through_association_name)
      relation = owner&.send(target_name)
      return if
        relation.nil?

      # explicitly scope the relation to records owned by the :through record
      reflection      = denormalized_owner_reflection_through(through_association_name, relation.klass)
      target_relation = relation.where(reflection.name => owner)

      source_attribute_value_was = send("#{source_attribute_name}_previously_was")

      target_relation.ids.each_slice(DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE) do |ids|
        DenormalizeAssociationAsyncJob.perform_later(
          source_class_name: self.class.name,
          source_id: id,
          source_attribute_name:,
          source_attribute_value_was:,
          target_class_name: target_relation.klass.name,
          target_ids: ids,
          target_attribute_name:,
        )
      end
    end

    # denormalized_owner_reflection_through reflects on the target's owner association,
    # i.e. the target's belongs_to association that points back at the :through record,
    # e.g. tokens are owned by their polymorphic bearer.
    def denormalized_owner_reflection_through(through_association_name, target_class)
      through_reflection = self.class.reflect_on_association(through_association_name)

      owner_reflections = target_class.reflect_on_all_associations(:belongs_to).select do |reflection|
        if through_reflection.polymorphic?
          reflection.polymorphic?
        else
          !reflection.polymorphic? && reflection.klass == through_reflection.klass
        end
      end

      case owner_reflections
      in [owner_reflection]
        owner_reflection
      in []
        raise ArgumentError, "no owner association found on #{target_class} for #{through_association_name.inspect}"
      else
        raise ArgumentError, "ambiguous owner association on #{target_class} for #{through_association_name.inspect}"
      end
    end

    # denormalized_record_owned_by? returns true when the record's owner association
    # foreign keys match the owner.
    def denormalized_record_owned_by?(record, owner, owner_reflection)
      return false if
        owner.nil?

      owned   = record.read_attribute(owner_reflection.foreign_key)  == owner.read_attribute(owner.class.primary_key)
      owned &&= record.read_attribute(owner_reflection.foreign_type) == owner.class.polymorphic_name if
        owner_reflection.polymorphic?

      owned
    end

    def write_denormalized_attribute_to_unpersisted_record(target_association_name, target_attribute_name, source_attribute_name)
      record = send(target_association_name)

      unless record.nil?
        record.write_attribute(target_attribute_name, read_attribute(source_attribute_name))
      end
    end

    def write_denormalized_attribute_to_persisted_record(target_association_name, target_attribute_name, source_attribute_name)
      record = send(target_association_name)

      unless record.nil?
        record.update(target_attribute_name => read_attribute(source_attribute_name))
      end
    end

    def write_denormalized_attribute_from_unpersisted_record(source_association_name, source_attribute_name, target_attribute_name)
      record = send(source_association_name)

      # NB(ezekg) if we're denormalizing a foreign key, we need to look up the association
      #           and denormalize the actual record, since it likely doesn't have a
      #           primary key assigned yet.
      if record.present? && (source_reflection = record.class.reflect_on_all_associations.find { it.foreign_key == source_attribute_name.to_s })
        target_reflection = self.class.reflect_on_all_associations.find { it.foreign_key == target_attribute_name.to_s }

        send(:"#{target_reflection.name}=", record.send(source_reflection.name))
      else
        write_attribute(target_attribute_name, record&.read_attribute(source_attribute_name))
      end
    end

    def write_denormalized_attribute_from_persisted_record(source_association_name, source_attribute_name, target_attribute_name)
      record = send(source_association_name)

      write_attribute(target_attribute_name, record&.read_attribute(source_attribute_name))
    end

    def write_denormalized_attribute_from_schrodingers_record(source_association_name, ...)
      record = send(source_association_name)

      if record&.persisted?
        write_denormalized_attribute_from_persisted_record(source_association_name, ...)
      else
        write_denormalized_attribute_from_unpersisted_record(source_association_name, ...)
      end
    end

    def write_denormalized_attribute_from_record_through(through_association_name, source_name, source_attribute_name, target_attribute_name)
      record = send(through_association_name)&.send(source_name)

      write_attribute(target_attribute_name, record&.read_attribute(source_attribute_name))
    end

    def validate_denormalized_attribute_from_persisted_record(source_association_name, source_attribute_name, target_attribute_name)
      record = send(source_association_name)

      unless read_attribute(target_attribute_name) == record&.read_attribute(source_attribute_name)
        if target_reflection = self.class.reflect_on_all_associations.find { it.foreign_key == target_attribute_name.to_s }
          errors.add target_reflection.name, :not_allowed, message: 'cannot be modified directly because it is a denormalized association'
        else
          errors.add target_attribute_name, :not_allowed, message: 'cannot be modified directly because it is a denormalized attribute'
        end
      end
    end

    def validate_denormalized_attribute_from_record_through(through_association_name, source_name, source_attribute_name, target_attribute_name)
      record = send(through_association_name)&.send(source_name)

      unless read_attribute(target_attribute_name) == record&.read_attribute(source_attribute_name)
        errors.add target_attribute_name, :not_allowed, message: 'cannot be modified directly because it is a denormalized attribute'
      end
    end
  end

  private

  class DenormalizeAssociationAsyncJob < ActiveJob::Base
    NOT_PROVIDED = Class.new

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
