# frozen_string_literal: true

class PlaintextMailerPreview < ActionMailer::Preview
  def low_activity_lifeline
    PlaintextMailer.low_activity_lifeline account: account
  end

  def trial_ending_soon_without_payment_method
    PlaintextMailer.trial_ending_soon_without_payment_method account: account
  end

  def trial_ending_soon_with_payment_method
    PlaintextMailer.trial_ending_soon_with_payment_method account: account
  end

  def first_payment_succeeded
    PlaintextMailer.first_payment_succeeded account: account
  end

  def prompt_for_testimonial
    PlaintextMailer.prompt_for_testimonial account: account
  end

  def prompt_for_review
    PlaintextMailer.prompt_for_review account: account
  end

  def prompt_for_first_impression
    PlaintextMailer.prompt_for_first_impression account: account
  end

  private

  def account = @account ||= Account.first
end
