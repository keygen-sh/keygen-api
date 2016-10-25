class BillingSerializer < BaseSerializer
  type :billings

  attributes [
    :id,
    :customer_id,
    :subscription_id,
    :subscription_period_start,
    :subscription_period_end,
    :subscription_status,
    :card_expiry,
    :card_brand,
    :card_last4,
    :created,
    :updated
  ]

  belongs_to :account
end
