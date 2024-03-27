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

  after_destroy :nullify_machines_for_user

  validates :user,
    uniqueness: { message: 'already exists', scope: %i[account_id license_id user_id] },
    scope: { by: :account_id }

  validate on: :create do
    next unless
      license.present? && user.present?

    next if
      user != license.owner

    errors.add :user, :conflict, message: 'already exists (user is attached through owner)'
  end

  scope :active, -> {
    joins(:license).merge(License.active)
  }

  private

  def nullify_machines_for_user
    # TODO(ezekg) Should add a policy configuration to allow you to destroy
    #             these machines instead of nilifying. (Do async.)
    license.machines.where(owner: user)
                    .update_all(
                      owner_id: nil,
                    )
  end
end
