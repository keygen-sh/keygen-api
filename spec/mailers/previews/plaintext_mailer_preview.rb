# frozen_string_literal: true

class PlaintextMailerPreview < ActionMailer::Preview

  def low_activity_lifeline
    PlaintextMailer.low_activity_lifeline account: account
  end

  def trial_ending_soon
    PlaintextMailer.trial_ending_soon account: account
  end

  def first_payment_succeeded
    PlaintextMailer.first_payment_succeeded account: account
  end

  private

  def account
    @account ||= Account.first
  end
end
