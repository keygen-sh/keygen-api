class LicenseSerializer < BaseSerializer
  type :licenses

  attribute :key, unless: -> { key.nil? }
  attributes :id,
             :expiry,
             :metadata,
             :encrypted,
             :created,
             :updated

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
#  key        :string
#  expiry     :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  metadata   :jsonb
#  id         :uuid             not null, primary key
#  user_id    :uuid
#  policy_id  :uuid
#  account_id :uuid
#
# Indexes
#
#  index_licenses_on_account_id  (account_id)
#  index_licenses_on_created_at  (created_at)
#  index_licenses_on_deleted_at  (deleted_at)
#  index_licenses_on_id          (id)
#  index_licenses_on_policy_id   (policy_id)
#  index_licenses_on_user_id     (user_id)
#
