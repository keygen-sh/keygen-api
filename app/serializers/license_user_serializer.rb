# frozen_string_literal: true

class LicenseUserSerializer < BaseSerializer
  type 'license-users'

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

  relationship :license do
    linkage always: true do
      { type: :licenses, id: @object.license_id }
    end
    link :related do
      @url_helpers.v1_account_license_path @object.account_id, @object.license_id
    end
  end

  relationship :user do
    linkage always: true do
      { type: :users, id: @object.user_id }
    end
    link :related do
      @url_helpers.v1_account_user_path @object.account_id, @object.user_id
    end
  end

  link :related do
    @url_helpers.v1_account_license_user_path @object.account_id, @object.license_id, @object.user_id
  end
end
