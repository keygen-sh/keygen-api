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

  before_create :enforce_active_licensed_user_limit_on_account!
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

  def enforce_active_licensed_user_limit_on_account!
    return unless account.trialing_or_free?

    active_licensed_user_count = account.active_licensed_user_count
    active_licensed_user_limit =
      if account.trialing? && account.billing.card.present?
        account.plan.max_licenses || account.plan.max_users
      else
        50
      end

    return if active_licensed_user_count.nil? ||
              active_licensed_user_limit.nil?

    if active_licensed_user_count >= active_licensed_user_limit
      errors.add :account, :alu_limit_exceeded, message: "Your tier's active licensed user limit of #{active_licensed_user_limit.to_fs(:delimited)} has been reached for your account. Please upgrade to a paid tier and add a payment method at https://app.keygen.sh/billing."

      throw :abort
    end
  end

  def nullify_machines_for_user
    # TODO(ezekg) Should add a policy configuration to allow you to destroy
    #             these machines instead of nilifying. (Do async.)
    license.machines.where(owner: user)
                    .update_all(
                      owner_id: nil,
                    )
  end
end
