# frozen_string_literal: true

class ReleaseSerializer < BaseSerializer
  type :releases

  attribute :name
  attribute :description
  attribute :signature
  attribute :checksum
  attribute :filename
  attribute :filetype do
    @object.filetype.key
  end
  attribute :filesize
  attribute :platform do
    @object.platform.key
  end
  attribute :channel do
    @object.channel.key
  end
  attribute :downloads do
    @object.download_count
  end
  attribute :upgrades do
    @object.upgrade_count
  end
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
  relationship :product do
    linkage always: true do
      { type: :products, id: @object.product_id }
    end
    link :related do
      @url_helpers.v1_account_release_product_path @object.account_id, @object
    end
  end
  relationship :constraints do
    link :related do
      @url_helpers.v1_account_release_constraints_path @object.account_id, @object
    end
  end
  relationship :artifact do
    linkage always: true do
      if @object.artifact.present?
        { type: :artifacts, id: @object.artifact.id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_release_artifact_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_release_path @object.account_id, @object
  end
end
