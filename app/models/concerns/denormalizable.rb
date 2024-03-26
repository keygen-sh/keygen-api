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
                                    "#{association_name.to_s}_#{attribute_name.to_s}"
                                  when Symbol,
                                       String
                                    "#{prefix.to_s}_#{attribute_name.to_s}"
                                  else
                                    attribute_name.to_s
                                  end

        unless reflection.collection?
          # FIXME(ezekg) Dedupe all of this mess.
          after_initialize  -> { write_attribute(prefixed_attribute_name, send(association_name)&.send(attribute_name)) }, if: :"#{reflection.foreign_key}_changed?"
          before_validation -> { write_attribute(prefixed_attribute_name, send(association_name)&.send(attribute_name)) }, if: :"#{reflection.foreign_key}_changed?", on: :create
          before_create     -> { write_attribute(prefixed_attribute_name, send(association_name)&.send(attribute_name)) }, if: :"#{reflection.foreign_key}_changed?"
          before_update     -> { write_attribute(prefixed_attribute_name, send(association_name)&.send(attribute_name)) }, if: :"#{reflection.foreign_key}_changed?"
        else
          raise ArgumentError, "must be a singular association: #{association_name.inspect}"
        end
      else
        raise ArgumentError, "invalid :from association: #{from.inspect}"
      end
    end

    def instrument_denormalized_attribute_to(attribute_name, to:, prefix:)
      case to
      in Symbol => association_name if reflection = reflect_on_association(association_name)
        prefixed_attribute_name = case prefix
                                  when true
                                    "#{association_name.to_s}_#{attribute_name.to_s}"
                                  when Symbol,
                                       String
                                    "#{prefix.to_s}_#{attribute_name.to_s}"
                                  else
                                    attribute_name.to_s
                                  end

        # FIXME(ezekg) Set to nil on destroy unless the association is dependent?
        # FIXME(ezekg) Dedupe all of this mess.
        if reflection.collection?
          after_initialize  -> { send(association_name).each { _1.write_attribute(prefixed_attribute_name, read_attribute(attribute_name)) } }, if: :"#{attribute_name}_changed?"
          before_validation -> { send(association_name).each { _1.write_attribute(prefixed_attribute_name, read_attribute(attribute_name)) } }, if: :"#{attribute_name}_changed?", on: :create
          before_create     -> { send(association_name).update_all(prefixed_attribute_name => read_attribute(attribute_name)) }, if: :"#{attribute_name}_changed?"
          before_update     -> { send(association_name).update_all(prefixed_attribute_name => read_attribute(attribute_name)) }, if: :"#{attribute_name}_changed?"
        else
          after_initialize  -> { send(association_name).write_attribute(prefixed_attribute_name, read_attribute(attribute_name)) }, if: :"#{attribute_name}_changed?"
          before_validation -> { send(association_name).write_attribute(prefixed_attribute_name, read_attribute(attribute_name)) }, if: :"#{attribute_name}_changed?", on: :create
          before_create     -> { send(association_name).update(prefixed_attribute_name => read_attribute(attribute_name)) }, if: :"#{attribute_name}_changed?"
          before_update     -> { send(association_name).update(prefixed_attribute_name => read_attribute(attribute_name)) }, if: :"#{attribute_name}_changed?"
        end
      else
        raise ArgumentError, "invalid :to association: #{to.inspect}"
      end
    end
  end
end
