class AccountMailer < ApplicationMailer

  def beta_invitation(account:, token:)
    @account, @token = account, token

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "You've been invited to the beta program!"
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
