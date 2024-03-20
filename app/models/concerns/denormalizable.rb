# frozen_string_literal: true

module Denormalizable
  extend ActiveSupport::Concern

  class_methods do
    def denormalizes(attribute_name, from: nil, to: nil, with: nil, prefix: nil)
      raise ArgumentError, 'must provide :from, :to, or :with (but not multiple)' unless
        from.present? ^ to.present? ^ with.present?

      case
      when from.present?
        instrument_denormalized_attribute_from(attribute_name, from:)
      when to.present?
        raise NotImplementedError, 'denormalizes :to is not supported yet'
      when with.present?
        instrument_denormalized_attribute_with(attribute_name, with:)
      else
        raise ArgumentError, 'must provide either :from, :to, or :with'
      end
    end

    private

    def instrument_denormalized_attribute_from(attribute_name, from:)
      case from
      in Symbol => association_name
        before_create     -> { write_attribute(attribute_name, send(association_name)&.read_attribute(attribute_name) ) }, if: :"#{association_name}_id_changed?"
        before_update     -> { write_attribute(attribute_name, send(association_name)&.read_attribute(attribute_name) ) }, if: :"#{association_name}_id_changed?"
        before_destroy    -> { write_attribute(attribute_name, nil ) }, unless: -> { association(association_name).reflection.belongs_to? && !association(association_name).options[:optional] }
      else
        raise ArgumentError, "invalid :from association: #{from.inspect}"
      end
    end

    def instrument_denormalized_attribute_with(attribute_name, method)
      # case with
      # in Proc => method
      #   instance_exec(&method)
      # in Symbol => method
      #   send(method)
      # else
      #   raise ArgumentError, "invalid :with method: #{with.inspect}"
      # end
    end
  end
end
