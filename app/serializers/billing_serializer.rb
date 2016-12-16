class BillingSerializer < BaseSerializer
  type :billings

  attributes :id,
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

  has_one :plan
end

# == Schema Information
#
# Table name: billings
#
#  customer_id               :string
#  subscription_status       :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  subscription_id           :string
#  subscription_period_start :datetime
#  subscription_period_end   :datetime
#  card_expiry               :datetime
#  card_brand                :string
#  card_last4                :string
#  state                     :string
#  deleted_at                :datetime
#  id                        :uuid             not null, primary key
#  account_id                :uuid
#
# Indexes
#
#  index_billings_on_account_id  (account_id)
#  index_billings_on_created_at  (created_at)
#  index_billings_on_deleted_at  (deleted_at)
#  index_billings_on_id          (id)
#
