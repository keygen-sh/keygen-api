class SerializableBilling < SerializableBase
  type 'billings'

  attribute :customer_id
  attribute :subscription_status
  attribute :created_at
  attribute :updated_at
  attribute :subscription_id
  attribute :subscription_period_start
  attribute :subscription_period_end
  attribute :card_expiry
  attribute :card_brand
  attribute :card_last4
  attribute :state

  has_one :plan
  has_one :account
  has_many :receipts
end
