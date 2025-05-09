# frozen_string_literal: true

class AccountSetting < ApplicationRecord
  include Keygen::PortableClass
  include Limitable, Orderable, Pageable
  include Accountable, Dirtyable, Aliasable

  VALID_KEYS = %w[
    default_license_permissions
    default_user_permissions
  ]

  has_account touch: true
  has_aliases :key

  validates :key, presence: true, uniqueness: { scope: :account_id }, inclusion: { in: VALID_KEYS, message: "must be one of: #{VALID_KEYS.join(', ')}" }
  validate on: %i[create update] do
    case self
    in key: :default_license_permissions | 'default_license_permissions', value: [*] => permissions
      unless (permissions & License.allowed_permissions).size == permissions.size
        errors.add :value, :not_allowed, message: 'must be an array of valid license permissions'
      end
    in key: :default_user_permissions | 'default_user_permissions', value: [*] => permissions
      unless (permissions & User.allowed_permissions).size == permissions.size
        errors.add :value, :not_allowed, message: 'must be an array of valid user permissions'
      end
    else
      errors.add :value, :not_allowed, message: 'must be a valid setting'
    end
  end
end
