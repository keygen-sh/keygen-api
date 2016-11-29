class Billing < ApplicationRecord
  AVAILABLE_EVENTS = %w[activate_trial activate_subscription pause_subscription resume_subscription cancel_subscription renew_subscription].freeze
  AVAILABLE_STATES = %w[pending trialing subscribed paused canceled].freeze
  ACTIVE_STATES = %w[pending trialing subscribed].freeze

  include AASM

  acts_as_paranoid

  belongs_to :account
  has_many :receipts, dependent: :destroy
  has_one :plan, through: :account

  validates :customer_id, presence: true

  before_destroy :close_customer_account

  aasm column: :state, whiny_transitions: false do
    state :pending, initial: true
    state :trialing
    state :subscribed
    state :paused
    state :canceled

    event :activate_trial do
      transitions from: :pending, to: :trialing, after: -> {
        Billings::CreateSubscriptionService.new(
          customer: customer_id,
          plan: plan.plan_id
        ).execute
      }
    end

    event :activate_subscription do
      transitions from: [:pending, :trialing], to: :subscribed
    end

    event :pause_subscription do
      transitions from: :subscribed, to: :paused, after: -> {
        Billings::DeleteSubscriptionService.new(
          subscription: subscription_id
        ).execute
      }
    end

    event :resume_subscription do
      transitions from: :paused, to: :subscribed, after: -> {
        # Setting a trial allows us to continue to use the previously 'paused'
        # subscription's billing cycle
        Billings::CreateSubscriptionService.new(
          customer: customer_id,
          trial: subscription_period_end,
          plan: plan.plan_id
        ).execute
      }
    end

    event :cancel_subscription do
      transitions from: [:pending, :trialing, :subscribed], to: :canceled, after: -> {
        AccountMailer.subscription_canceled(account: account).deliver_later

        Billings::DeleteSubscriptionService.new(
          subscription: subscription_id
        ).execute
      }
    end

    event :renew_subscription do
      transitions from: :canceled, to: :subscribed, after: -> {
        Billings::UpdateSubscriptionService.new(
          subscription: subscription_id,
          plan: plan.plan_id
        ).execute
      }
    end
  end

  def active?
    ACTIVE_STATES.include? state
  end

  def card
    @card ||= if card_expiry && card_brand && card_last4
                OpenStruct.new({
                  expiry: card_expiry,
                  brand: card_brand,
                  last4: card_last4
                })
              else
                nil
              end
  end

  private

  def close_customer_account
    Billings::DeleteCustomerService.new(
      customer: customer_id
    ).execute
  end
end

# == Schema Information
#
# Table name: billings
#
#  id                        :integer          not null, primary key
#  customer_id               :string
#  subscription_status       :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :integer
#  subscription_id           :string
#  subscription_period_start :datetime
#  subscription_period_end   :datetime
#  card_expiry               :datetime
#  card_brand                :string
#  card_last4                :string
#  state                     :string
#  deleted_at                :datetime
#
# Indexes
#
#  index_billings_on_account_id_and_customer_id      (account_id,customer_id)
#  index_billings_on_account_id_and_subscription_id  (account_id,subscription_id)
#  index_billings_on_deleted_at                      (deleted_at)
#
