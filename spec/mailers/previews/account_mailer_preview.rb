class AccountMailerPreview < ActionMailer::Preview

  def beta_ending_today
    AccountMailer.beta_ending_today account: account
  end

  def follow_up
    AccountMailer.follow_up account: account
  end

  def payment_method_missing
    AccountMailer.payment_method_missing account: account
  end

  def payment_failed
    AccountMailer.payment_failed account: account
  end

  def subscription_canceled
    AccountMailer.subscription_canceled account: account
  end

  def first_payment_succeeded
    AccountMailer.first_payment_succeeded account: account
  end

  def welcome
    AccountMailer.welcome account: account
  end

  private

  def account
    @account ||= Account.first
  end
end
