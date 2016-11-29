class LicenseSerializer < BaseSerializer
  type :licenses

  attribute :key, unless: -> { key.nil? }
  attributes :id,
             :expiry,
             :metadata,
             :encrypted,
             :created,
             :updated

  belongs_to :user
  belongs_to :policy
  has_one :product, through: :policy

  def key
    if object.policy.encrypted?
      object.raw
    else
      object.key
    end
  end

  def encrypted
    object.policy.encrypted?
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
#  metadata   :jsonb
#
# Indexes
#
#  index_licenses_on_account_id_and_id         (account_id,id)
#  index_licenses_on_deleted_at                (deleted_at)
#  index_licenses_on_key_and_account_id        (key,account_id)
#  index_licenses_on_policy_id_and_account_id  (policy_id,account_id)
#  index_licenses_on_user_id_and_account_id    (user_id,account_id)
#
