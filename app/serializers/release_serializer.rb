# frozen_string_literal: true

class ReleaseSerializer < BaseSerializer
  type 'releases'

  attribute :name
  attribute :description
  attribute :channel do
    @object.channel&.key
  end
  attribute :status
  attribute :tag
  attribute :version
  attribute :semver do
    semver = @object.semver

    {
      major: semver.major,
      minor: semver.minor,
      patch: semver.patch,
      prerelease: semver.pre_release,
      build: semver.build,
    }
  end
  attribute :metadata do
    @object.metadata&.transform_keys { |k| k.to_s.camelize :lower } or {}
  end
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end
  attribute :yanked do
    @object.yanked_at
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
      { type: :products, id: @object.product_id }
    end
    link :related do
      @url_helpers.v1_account_release_product_path @object.account_id, @object
    end
  end

  relationship :entitlements do
    link :related do
      @url_helpers.v1_account_release_entitlements_path @object.account_id, @object
    end
  end

  relationship :constraints do
    link :related do
      @url_helpers.v1_account_release_release_entitlement_constraints_path @object.account_id, @object
    end
  end

  relationship :artifacts do
    link :related do
      @url_helpers.v1_account_release_release_artifacts_path @object.account_id, @object
    end
  end

  relationship :upgrade do
    link :related do
      @url_helpers.v1_account_release_upgrade_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_release_path @object.account_id, @object
  end
end
