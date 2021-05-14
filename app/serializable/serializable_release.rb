# frozen_string_literal: true

class SerializableRelease < SerializableBase
  type :releases

  attribute :name
  attribute :key
  attribute :gated do
    @object.gated?
  end
  attribute :size
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
      @url_helpers.v1_account_product_path @object.account_id, @object.product_id
    end
  end
  relationship :platform do
    linkage always: true do
      { type: :platforms, id: @object.release_platform_id }
    end
    link :related do
      # TODO(ezekg)
    end
  end
  relationship :channel do
    linkage always: true do
      { type: :channels, id: @object.release_channel_id }
    end
    link :related do
      # TODO(ezekg)
    end
  end
  relationship :downloads do
    link :related do
      # TODO(ezekg)
    end
    meta do
      {
        count: @object.download_count
      }
    end
  end

  link :self do
    @url_helpers.v1_account_product_release_path @object.account_id, @object.product_id, @object.id
  end
end
