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
  relationship :release do
    linkage always: true do
      { type: :releases, id: @object.release_id }
    end
    link :related do
      @url_helpers.v1_account_release_path @object.account_id, @object.release_id
    end
  end

  link :related do
    @url_helpers.v1_account_release_artifact_path @object.account_id, @object.release_id, @object
  end

  link :self do
    @url_helpers.v1_account_artifact_path @object.account_id, @object
  end
end
