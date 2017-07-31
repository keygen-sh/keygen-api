class AccountMailer < ApplicationMailer
  default from: "Keygen <support@keygen.sh>"
  layout "account_mailer"

  def pricing_change(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Update: we've simplified our pricing"
    end
  end

  def beta_ending_today(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "The Keygen beta is ending within the next 24 hours"
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
