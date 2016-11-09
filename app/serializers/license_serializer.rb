class LicenseSerializer < BaseSerializer
  type :licenses

  attributes [
    :id,
    :key,
    :expiry,
    :meta,
    :created,
    :updated
  ]

  belongs_to :user
  belongs_to :policy
  has_many :machines
end

# == Schema Information
#
# Table name: licenses
#
#  id         :integer          not null, primary key
#  key        :string
#  expiry     :datetime
#  user_id    :integer
#  meta       :hash
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  policy_id  :integer
#  account_id :integer
#
# Indexes
#
#  index_licenses_on_account_id  (account_id)
#  index_licenses_on_policy_id   (policy_id)
#  index_licenses_on_user_id     (user_id)
#
