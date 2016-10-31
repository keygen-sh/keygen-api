class AccountSerializer < BaseSerializer
  type :accounts

  attributes [
    :id,
    :name,
    :subdomain,
    :created,
    :updated
  ]

  belongs_to :plan
  has_many :webhook_endpoints
  has_many :webhook_events
  has_many :users
  has_many :products
  has_many :policies, through: :products
  has_many :licenses, through: :policies
  has_one :billing
end

# == Schema Information
#
# Table name: accounts
#
#  id                 :integer          not null, primary key
#  name               :string
#  subdomain          :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  plan_id            :integer
#  activation_token   :string
#  activation_sent_at :datetime
#
# Indexes
#
#  index_accounts_on_subdomain  (subdomain)
#
