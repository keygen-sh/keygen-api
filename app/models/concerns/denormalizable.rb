# frozen_string_literal: true

module Denormalizable
  extend ActiveSupport::Concern

  class_methods do
    cattr_accessor :denormalized_attributes, default: Set.new

    # TODO(ezekg) Active Record's normalizes method accepts an array of names. Should we?
    def denormalizes(attribute_name, with: nil, from: nil, to: nil, prefix: nil)
      raise ArgumentError, 'must provide :from, :to, or :with (but not multiple)' unless
        from.present? ^ to.present? ^ with.present?

      # TODO(ezekg) Should we store more information, such as :to or :from?
      denormalized_attributes << attribute_name

      case
      when from.present?
        instrument_denormalized_attribute_from(attribute_name, from:, prefix:)
      when to.present?
        instrument_denormalized_attribute_to(attribute_name, to:, prefix:)
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

        after_initialize  -> { write_denormalized_attribute_from_unpersisted_record(association_name, attribute_name, prefixed_attribute_name) }, if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }
        before_validation -> { write_denormalized_attribute_from_unpersisted_record(association_name, attribute_name, prefixed_attribute_name) }, if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }, on: :create
        before_validation -> { write_denormalized_attribute_from_persisted_record(association_name, attribute_name, prefixed_attribute_name) },   if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }, on: :update
        before_create     -> { write_denormalized_attribute_from_persisted_record(association_name, attribute_name, prefixed_attribute_name) },   if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }
        before_update     -> { write_denormalized_attribute_from_persisted_record(association_name, attribute_name, prefixed_attribute_name) },   if: -> { send(:"#{reflection.foreign_key}_changed?") || send(:"#{reflection.name}_changed?") }
      else
        raise ArgumentError, "invalid :from association: #{from.inspect}"
      end
    end

    def instrument_denormalized_attribute_to(attribute_name, to:, prefix:)
      case to
      in Symbol => association_name if reflection = reflect_on_association(association_name)
        prefixed_attribute_name = case prefix
                                  when true
                                    "#{name}_#{attribute_name}"
                                  when Symbol,
                                       String
                                    "#{prefix}_#{attribute_name}"
                                  else
                                    attribute_name.to_s
                                  end

        # FIXME(ezekg) Set to nil on destroy unless the association is dependent?
        if reflection.collection?
          after_initialize  -> { write_denormalized_attribute_to_unpersisted_relation(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?"
          before_validation -> { write_denormalized_attribute_to_unpersisted_relation(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", on: :create
          before_validation -> { write_denormalized_attribute_to_persisted_relation(association_name, prefixed_attribute_name, attribute_name) },   if: :"#{attribute_name}_changed?", on: :update
          before_create     -> { write_denormalized_attribute_to_persisted_relation(association_name, prefixed_attribute_name, attribute_name) },   if: :"#{attribute_name}_changed?"
          before_update     -> { write_denormalized_attribute_to_persisted_relation(association_name, prefixed_attribute_name, attribute_name) },   if: :"#{attribute_name}_changed?"
        else
          after_initialize  -> { write_denormalized_attribute_to_unpersisted_record(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?"
          before_validation -> { write_denormalized_attribute_to_unpersisted_record(association_name, prefixed_attribute_name, attribute_name) }, if: :"#{attribute_name}_changed?", on: :create
          before_validation -> { write_denormalized_attribute_to_persisted_record(association_name, prefixed_attribute_name, attribute_name) },   if: :"#{attribute_name}_changed?", on: :update
          before_create     -> { write_denormalized_attribute_to_persisted_record(association_name, prefixed_attribute_name, attribute_name) },   if: :"#{attribute_name}_changed?"
          before_update     -> { write_denormalized_attribute_to_persisted_record(association_name, prefixed_attribute_name, attribute_name) },   if: :"#{attribute_name}_changed?"
        end
      else
        raise ArgumentError, "invalid :to association: #{to.inspect}"
      end
    end
  end

  # FIXME(ezekg) Move this out into a separate module so that we don't pollute the model.
  # FIXME(ezekg) These could probably figure out persistence automatically.
  included do
    private

    def write_denormalized_attribute_to_unpersisted_relation(target_association_name, target_attribute_name, source_attribute_name)
      relation = send(target_association_name)

      relation.each do |record|
        record.write_attribute(target_attribute_name, read_attribute(source_attribute_name))
      end
    end

    def write_denormalized_attribute_to_persisted_relation(target_association_name, target_attribute_name, source_attribute_name)
      relation = send(target_association_name)

      relation.update_all(target_attribute_name => read_attribute(source_attribute_name))
    end

    def write_denormalized_attribute_to_unpersisted_record(target_association_name, target_attribute_name, source_attribute_name)
      record = send(target_association_name)

      record.write_attribute(target_attribute_name, read_attribute(source_attribute_name))
    end

    def write_denormalized_attribute_to_persisted_record(target_association_name, target_attribute_name, source_attribute_name)
      record = send(target_association_name)

      record.update(target_attribute_name => read_attribute(source_attribute_name))
    end

    def write_denormalized_attribute_from_unpersisted_record(source_association_name, source_attribute_name, target_attribute_name)
      record = send(source_association_name)

      # If we're denormalizing a foreign key, we need to look up the association and denormalize
      # the actual record, since it likely doesn't have an ID assigned yet.
      if record&.read_attribute(source_attribute_name).nil? && (source_reflection = record.class.reflect_on_all_associations.find { _1.foreign_key == source_attribute_name.to_s })
        target_reflection = self.class.reflect_on_all_associations.find { _1.foreign_key == target_attribute_name.to_s }

        send(:"#{target_reflection.name}=", record.send(source_reflection.name))
      else
        write_attribute(target_attribute_name, record&.read_attribute(source_attribute_name))
      end
    end

    def write_denormalized_attribute_from_persisted_record(source_association_name, source_attribute_name, target_attribute_name)
      record = send(source_association_name)

      write_attribute(target_attribute_name, record&.read_attribute(source_attribute_name))
    end
  end
end
