# frozen_string_literal: true

module Denormalizable
  extend ActiveSupport::Concern

  DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE = 1_000

  class_methods do
    def denormalizes(*attribute_names, with: nil, from: nil, to: nil, prefix: nil)
      raise ArgumentError, 'must provide :from, :to, or :with (but not multiple)' unless
        from.present? ^ to.present? ^ with.present?

      case
      when from.present?
        attribute_names.each { instrument_denormalized_attribute_from(it, from:, prefix:) }
      when to.present?
        attribute_names.each { instrument_denormalized_attribute_to(it, to:, prefix:) }
      when with.present?
        raise NotImplementedError, 'denormalizes :with is not supported yet'
      else
        raise ArgumentError, 'must provide either :from, :to, or :with'
      end
    end

    private

    def instrument_denormalized_attribute_from(attribute_name, from:, prefix:)
      case from
      in Symbol => association_name if reflection = reflect_on_association(association_name)
        prefixed_attribute_name = case prefix
                                  when true
                                    "#{association_name}_#{attribute_name}"
                                  when Symbol,
                                       String
                                    "#{prefix}_#{attribute_name}"
                                  else
                                    attribute_name.to_s
                                  end

        if reflection.collection?
          raise ArgumentError, "must be a singular association: #{association_name.inspect}"
        end

        # FIXME(ezekg) after_initialize ignores prepend: false
        set_callback :initialize, :after, -> { write_denormalized_attribute_from_schrodingers_record(association_name, attribute_name, prefixed_attribute_name) }, if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }, unless: :persisted?, prepend: false
        before_validation -> { write_denormalized_attribute_from_schrodingers_record(association_name, attribute_name, prefixed_attribute_name) }, if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }, on: :create
        before_update -> { write_denormalized_attribute_from_persisted_record(association_name, attribute_name, prefixed_attribute_name) }, if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }

        # make sure validation fails if our denormalized column is modified directly
        validate -> { validate_denormalized_attribute_from_persisted_record(association_name, attribute_name, prefixed_attribute_name) }, if: :"#{prefixed_attribute_name}_changed?", on: :update

        denormalized_attributes << attribute_name
      else
        raise ArgumentError, "invalid :from association: #{from.inspect}"
      end
    end

    def instrument_denormalized_attribute_to(attribute_name, to:, prefix:)
      case to
      in Symbol => association_name if reflection = reflect_on_association(association_name)
        prefixed_attribute_name = case prefix
                                  when true
                                    "#{association_name}_#{attribute_name}"
                                  when Symbol,
                                       String
                                    "#{prefix}_#{attribute_name}"
                                  else
                                    attribute_name.to_s
                                  end

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
  end

  # FIXME(ezekg) Move this out into a separate module so that we don't pollute the model.
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

      # If we're denormalizing a foreign key, we need to look up the association and denormalize
      # the actual record, since it likely doesn't have an ID assigned yet.
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
