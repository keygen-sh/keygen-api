# frozen_string_literal: true

class ReleasePackageSerializer < BaseSerializer
  type 'packages'

  attribute :name
  attribute :key
  attribute :metadata do
    @object.metadata&.transform_keys { |k| k.to_s.camelize :lower } or {}
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

  relationship :engine do
    linkage always: true do
      if @object.release_engine_id.present?
        { type: :engines, id: @object.release_engine_id }
      else
        nil
      end
    end
    link :related do
      if @object.release_engine_id.present?
        @url_helpers.v1_account_release_engine_path @object.account_id, @object.release_engine_id
      else
        nil
      end
    end
  end

  relationship :product do
    linkage always: true do
      { type: :products, id: @object.product_id }
    end
    link :related do
      @url_helpers.v1_account_product_path @object.account_id, @object.product_id
    end
  end

  link :related do
    @url_helpers.v1_account_release_package_path @object.account_id, @object
  end
end
