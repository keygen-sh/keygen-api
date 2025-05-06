# frozen_string_literal: true

class LicenseUser < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :license, counter_cache: true
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

  # Disallow user overages according to policy overage strategy
  validate on: :create do
    next unless
      license.present? && license.max_users?

    next if
      license.always_allow_overage?

    next_user_count = license.users_count + 1 # for the current license user
    next unless
      next_user_count > license.max_users

    next if
      license.allow_1_25x_overage? && next_user_count <= license.max_users * 1.25

    next if
      license.allow_1_5x_overage? && next_user_count <= license.max_users * 1.5

    next if
      license.allow_2x_overage? && next_user_count <= license.max_users * 2

    errors.add :base, :limit_exceeded, message: "user count has exceeded maximum allowed for license (#{license.max_users})"
  end

  scope :active, -> {
    joins(:license).merge(License.active)
  }

  private

  def enforce_active_licensed_user_limit_on_account!
    return unless account.trialing_or_free?

    active_licensed_user_count = account.active_licensed_user_count
    active_licensed_user_limit = account.plan.max_licenses ||
                                 account.plan.max_users

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
    Machine.where(account_id:, license_id:, owner_id: user_id)
           .update_all(
             owner_id: nil,
           )
  end
end
