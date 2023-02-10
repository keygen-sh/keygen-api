# frozen_string_literal: true

class ReleaseUpgradeLinkSerializer < BaseSerializer
  type 'release-upgrade-links'

  attribute :url
  attribute :ttl
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
        unless @object.environment_id.nil?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        end
      end
    end
  end

  relationship :release do
    linkage always: true do
      { type: :releases, id: @object.release_id }
    end
    link :related do
      @url_helpers.v1_account_release_path @object.account_id, @object.release_id
    end
  end

  link :related do
    @url_helpers.v1_account_release_artifact_path @object.account_id, @object.release_id
  end
end
