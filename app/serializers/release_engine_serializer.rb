# frozen_string_literal: true

class ReleaseEngineSerializer < BaseSerializer
  type 'engines'

  attribute :name
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

  link :related do
    @url_helpers.v1_account_release_engine_path @account, @object
  end
end
