# frozen_string_literal: true

class PolicyEntitlementSerializer < BaseSerializer
  type "policy-entitlements"

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

  relationship :entitlement do
    linkage always: true do
      { type: :entitlements, id: @object.entitlement_id }
    end
    link :related do
      @url_helpers.v1_account_entitlement_path @object.account_id, @object.entitlement_id
    end
  end

  relationship :policy do
    linkage always: true do
      { type: :polices, id: @object.policy_id }
    end
    link :related do
      @url_helpers.v1_account_policy_path @object.account_id, @object.policy_id
    end
  end

  link :related do
    @url_helpers.v1_account_policy_entitlement_path @object.account_id, @object.policy_id, @object.entitlement_id
  end
end
