# frozen_string_literal: true

class ReleaseArtifactSerializer < BaseSerializer
  type 'artifacts'

  attribute :filename
  attribute :filetype do
    @object.filetype&.key
  end
  attribute :filesize
  attribute :platform do
    @object.platform&.key
  end
  attribute :arch do
    @object.arch&.key
  end
  attribute :signature
  attribute :checksum
  attribute :status
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

  relationship :release do
    linkage always: true do
      { type: :releases, id: @object.release_id }
    end
    link :related do
      @url_helpers.v1_account_release_path @object.account_id, @object.release_id
    end
  end

  link :redirect, if: -> { @object.redirect_url? } do
    @object.redirect_url
  end

  link :related do
    @url_helpers.v1_account_release_release_artifact_path @object.account_id, @object.release_id, @object
  end

  link :self do
    @url_helpers.v1_account_release_artifact_path @object.account_id, @object
  end
end
