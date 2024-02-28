# frozen_string_literal: true

class LicenseUser < ApplicationRecord
  include Environmental
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :license
  belongs_to :user

  has_environment default: -> { license&.environment_id }

  # Automatically inherit the license/user's account ID. This
  # makes creating these records a lot easier.
  before_validation -> {
    self.account_id = license.account_id || user.account_id
  }

  validates :license,
    uniqueness: { message: 'already exists', scope: %i[account_id license_id user_id] },
    scope: { by: :account_id }

  validates :user,
    uniqueness: { message: 'already exists', scope: %i[account_id license_id user_id] },
    scope: { by: :account_id }
end
