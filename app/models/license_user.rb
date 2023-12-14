# frozen_string_literal: true

class LicenseUser < ApplicationRecord
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :license
  belongs_to :user

  has_environment default: -> { license&.environment_id }
  has_account default: -> { license&.account_id }

  validates :license,
    uniqueness: { message: 'already exists', scope: %i[account_id license_id user_id] },
    scope: { by: :account_id }

  validates :user,
    uniqueness: { message: 'already exists', scope: %i[account_id license_id user_id] },
    scope: { by: :account_id }
end
