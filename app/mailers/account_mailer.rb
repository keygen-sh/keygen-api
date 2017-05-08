class AccountMailer < ApplicationMailer
  default from: "Zeke from Keygen <zeke@keygen.sh>"
  layout "account_mailer"

  def beta_invitation(account:, token:)
    @account, @token = account, token

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "You've been invited to join the Keygen beta!"
    end
  end

  def beta_ending_soon(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "The beta is ending tomorrow! (Meaning we're launching soon!)"
    end
  end

  def follow_up(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Do you have any questions/feedback before giving Keygen a spin?"
    end
  end

  def payment_method_missing(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Your account is missing payment details"
    end
  end

  def payment_failed(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "There was a problem with your payment"
    end
  end

  def subscription_canceled(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Your subscription has been canceled"
    end
  end

  def first_payment_succeeded(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Thanks so much for subscribing!"
    end
  end

  def welcome(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Welcome to Keygen!"
    end
  end
end
