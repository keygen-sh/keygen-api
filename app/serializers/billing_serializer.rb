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
#  deleted_at                :datetime
#
# Indexes
#
#  index_billings_on_account_id_and_customer_id      (account_id,customer_id)
#  index_billings_on_account_id_and_subscription_id  (account_id,subscription_id)
#  index_billings_on_deleted_at                      (deleted_at)
#
