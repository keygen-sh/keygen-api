# frozen_string_literal: true

class SecondFactorSerializer < BaseSerializer
  type "second-factors"

  attribute :uri, if: -> { @object.uri.present? && @context != :webhook } do
    @object.uri
  end
  attribute :enabled
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
  relationship :user do
    linkage always: true do
      { type: :users, id: @object.user_id }
    end
    link :related do
      @url_helpers.v1_account_user_path @object.account_id, @object.user_id
    end
  end

  link :self do
    @url_helpers.v1_account_user_second_factor_path @object.account_id, @object.user_id, @object
  end
end
