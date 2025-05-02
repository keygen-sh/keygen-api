# frozen_string_literal: true

class ProductSerializer < BaseSerializer
  type 'products'

  attribute :name
  attribute :code
  attribute :distribution_strategy
  attribute :url
  attribute :platforms
  ee do
    attribute :permissions do
      @object.permissions.actions
    end
  end
  attribute :metadata do
    @object.metadata&.deep_transform_keys { _1.to_s.camelize :lower } or {}
  end
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
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

  relationship :policies do
    link :related do
      @url_helpers.v1_account_product_policies_path @object.account_id, @object
    end
  end

  relationship :licenses do
    link :related do
      @url_helpers.v1_account_product_licenses_path @object.account_id, @object
    end
  end

  relationship :machines do
    link :related do
      @url_helpers.v1_account_product_machines_path @object.account_id, @object
    end
  end

  relationship :users do
    link :related do
      @url_helpers.v1_account_product_users_path @object.account_id, @object
    end
  end

  relationship :tokens do
    link :related do
      @url_helpers.v1_account_product_tokens_path @object.account_id, @object
    end
  end

  relationship :platforms do
    link :related do
      @url_helpers.v1_account_product_release_platforms_path @object.account_id, @object
    end
  end

  relationship :channels do
    link :related do
      @url_helpers.v1_account_product_release_channels_path @object.account_id, @object
    end
  end

  relationship :releases do
    link :related do
      @url_helpers.v1_account_product_releases_path @object.account_id, @object
    end
  end

  relationship :artifacts do
    link :related do
      @url_helpers.v1_account_product_release_artifacts_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_product_path @object.account_id, @object
  end
end
