# frozen_string_literal: true

class LicenseFileSerializer < BaseSerializer
  type 'license-files'

  attribute :certificate
  attribute :includes
  attribute :ttl
  attribute :expiry do
    @object.expires_at
  end
  attribute :issued do
    @object.issued_at
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
end
