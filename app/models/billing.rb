# frozen_string_literal: true

class Billing < ApplicationRecord
  AVAILABLE_EVENTS = %w[activate_trial activate_subscription pause_subscription resume_subscription cancel_subscription_at_period_end cancel_subscription renew_subscription].freeze
  AVAILABLE_STATES = %w[pending trialing subscribed paused canceling canceled].freeze
  ACTIVE_STATES = %w[pending trialing subscribed canceling].freeze

  include AASM

  belongs_to :account, touch: true
  has_many :receipts, dependent: :destroy
  has_one :plan, through: :account

  validates :customer_id, presence: true,
    if: -> { Keygen.multiplayer? }

  before_destroy :close_customer_account

  aasm column: :state, whiny_transitions: false do
    state :pending, initial: true
    state :trialing
    state :subscribed
    state :paused
    state :canceling
    state :canceled

    event :activate_trial do
      transitions from: %i[pending canceling canceled], to: :trialing
    end

    event :activate_subscription do
      transitions from: %i[pending trialing canceling canceled], to: :subscribed
    end

    event :pause_subscription do
      transitions from: %i[trialing subscribed], to: :paused, after: -> {
        Billings::DeleteSubscriptionService.call(
          subscription: subscription_id
        )
      }
    end

    event :resume_subscription do
      transitions from: %i[paused], to: :pending, after: -> {
        # Setting a trial allows us to continue to use the previously 'paused'
        # subscription's billing cycle
        Billings::CreateSubscriptionService.call(
          customer: customer_id,
          trial_end: subscription_period_end.to_i,
          plan: plan.plan_id
        )
      }
    end

    event :cancel_subscription_at_period_end do
      transitions from: %i[pending trialing subscribed], to: :canceling, after: -> {
        Billings::DeleteSubscriptionService.call(
          subscription: subscription_id,
          at_period_end: true
        )
      }
    end

    event :cancel_subscription do
      transitions from: %i[pending trialing subscribed canceling], to: :canceled, after: -> {
        AccountMailer.subscription_canceled(account: account).deliver_later if %i[subscribed canceling].include?(aasm.from_state)

        Billings::DeleteSubscriptionService.call(
          subscription: subscription_id,
          at_period_end: false
        )
      }
    end

    event :renew_subscription do
      transitions from: %i[canceling], to: :pending, after: -> {
        Billings::UpdateSubscriptionService.call(
          subscription: subscription_id,
          plan: plan.plan_id
        )
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
    Billings::DeleteCustomerService.call(
      customer: customer_id
    )
  end
end
