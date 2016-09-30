class BillingSerializer < BaseSerializer
  type :billings

  attributes [
    :id,
    :external_customer_id,
    :external_subscription_id,
    :external_subscription_period_start,
    :external_subscription_period_end,
    :external_subscription_status,
    :card_expiry,
    :card_brand,
    :card_last4,
    :created,
    :updated
  ]

  belongs_to :customer, polymorphic: true
end
