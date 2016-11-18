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

  def key
    if object.policy.encrypted?
      object.raw
    else
      object.key
    end
  end
end

# == Schema Information
#
# Table name: licenses
#
#  id         :integer          not null, primary key
#  key        :string
#  expiry     :datetime
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  policy_id  :integer
#  account_id :integer
#  deleted_at :datetime
#  meta       :json
#
# Indexes
#
#  index_licenses_on_account_id  (account_id)
#  index_licenses_on_deleted_at  (deleted_at)
#  index_licenses_on_key         (key)
#  index_licenses_on_policy_id   (policy_id)
#  index_licenses_on_user_id     (user_id)
#
