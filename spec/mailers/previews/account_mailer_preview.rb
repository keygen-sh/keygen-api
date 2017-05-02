class AccountMailerPreview < ActionMailer::Preview

  def beta_invitation
    token, enc = account.generate_encrypted_token :invite_token do |token|
      "#{account.id.delete "-"}.#{token}"
    end

    account.invite_sent_at = Time.zone.now
    account.invite_token   = enc

    AccountMailer.beta_invitation account: account, token: token
  end

  def beta_ending_soon
    AccountMailer.beta_ending_soon account: account
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
