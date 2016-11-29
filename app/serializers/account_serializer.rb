class AccountSerializer < BaseSerializer
  type :accounts

  attributes :id,
             :company,
             :name,
             :created,
             :updated

  belongs_to :plan
end

# == Schema Information
#
# Table name: accounts
#
#  id                 :integer          not null, primary key
#  company            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  plan_id            :integer
#  activation_token   :string
#  activation_sent_at :datetime
#  deleted_at         :datetime
#  name               :string
#
# Indexes
#
#  index_accounts_on_deleted_at  (deleted_at)
#  index_accounts_on_id          (id)
#  index_accounts_on_name        (name)
#
