class BillingSerializer < BaseSerializer
  type "billings"

  attributes [
    :id,
    :external_customer_id,
    :external_subscription_id,
    :external_status,
    :created,
    :updated
  ]

  belongs_to :customer, polymorphic: true
end
