class AccountSerializer < BaseSerializer
  type :accounts

  attributes :id,
             :name,
             :slug,
             :created,
             :updated
end

# == Schema Information
#
# Table name: accounts
#
#  name               :string
#  slug               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activation_token   :string
#  activation_sent_at :datetime
#  deleted_at         :datetime
#  id                 :uuid             not null, primary key
#  plan_id            :uuid
#
# Indexes
#
#  index_accounts_on_created_at  (created_at)
#  index_accounts_on_deleted_at  (deleted_at)
#  index_accounts_on_id          (id)
#  index_accounts_on_plan_id     (plan_id)
#  index_accounts_on_slug        (slug)
#
