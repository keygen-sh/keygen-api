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

# == Schema Information
#
# Table name: billings
#
#  id                        :integer          not null, primary key
#  customer_id               :string
#  subscription_status       :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :integer
#  subscription_id           :string
#  subscription_period_start :datetime
#  subscription_period_end   :datetime
#  card_expiry               :datetime
#  card_brand                :string
#  card_last4                :string
#  state                     :string
#
# Indexes
#
#  index_billings_on_customer_id      (customer_id)
#  index_billings_on_subscription_id  (subscription_id)
#
