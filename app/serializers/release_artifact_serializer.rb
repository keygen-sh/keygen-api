# frozen_string_literal: true

class ReleaseArtifactSerializer < BaseSerializer
  type 'artifacts'

  attribute :key
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

  link :self do
    @url_helpers.v1_account_artifact_path @object.account_id, @object
  end
end
