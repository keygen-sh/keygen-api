class SerializableBilling < SerializableBase
  type :billings

  attribute :subscription_status
  attribute :subscription_period_start
  attribute :subscription_period_end
  attribute :card_expiry
  attribute :card_brand
  attribute :card_last4
  attribute :state
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
    linkage always: true
    link :related do
      @url_helpers.v1_account_path @object.account
    end
  end
  relationship :plan do
    linkage always: true
    link :related do
      @url_helpers.v1_plan_path @object.account.plan
    end
  end

  link :self do
    @url_helpers.v1_account_billing_path @object.account
  end
end
