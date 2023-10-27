# frozen_string_literal: true

class MachineComponentSerializer < BaseSerializer
  type 'components'

  attribute :fingerprint
  attribute :name
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end
  attribute :metadata do
    @object.metadata&.deep_transform_keys { _1.to_s.camelize :lower } or {}
  end

  relationship :account do
    linkage always: true do
      { type: :accounts, id: @object.account_id }
    end
    link :related do
      @url_helpers.v1_account_path @object.account_id
    end
  end

  ee do
    relationship :environment do
      linkage always: true do
        if @object.environment_id.present?
          { type: :environments, id: @object.environment_id }
        else
          nil
        end
      end
      link :related do
        if @object.environment_id.present?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        else
          nil
        end
      end
    end
  end

  relationship :product do
    linkage always: true do
      { type: :products, id: @object.product&.id }
    end
    link :related do
      @url_helpers.v1_account_machine_component_product_path @object.account_id, @object
    end
  end

  relationship :license do
    linkage always: true do
      { type: :licenses, id: @object.license&.id }
    end
    link :related do
      @url_helpers.v1_account_machine_component_license_path @object.account_id, @object
    end
  end

  relationship :machine do
    linkage always: true do
      { type: :machines, id: @object.machine_id }
    end
    link :related do
      @url_helpers.v1_account_machine_component_machine_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_machine_component_path @object.account_id, @object
  end
end
