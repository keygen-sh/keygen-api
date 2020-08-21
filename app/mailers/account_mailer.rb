# frozen_string_literal: true

class AccountMailer < ApplicationMailer
  default from: "Keygen Support <support@keygen.sh>"
  layout "account_mailer"

  def request_limit_exceeded(account:, plan:, request_count:, request_limit:)
    @account = account
    @plan = plan
    @report = OpenStruct.new(
      request_count: request_count,
      request_limit: request_limit
    )

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "You've exceeded the daily API request limit of your Keygen account"
    end
  end

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

  def payment_method_missing(account:, invoice: nil)
    @account = account
    @invoice = Stripe::Util.convert_to_stripe_object(invoice, symbolize_keys: true) if invoice.present?

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Your account is missing payment details"
    end
  end

  def payment_failed(account:, invoice: nil)
    @account = account
    @invoice = Stripe::Util.convert_to_stripe_object(invoice, symbolize_keys: true) if invoice.present?

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

      mail to: admin.email, subject: "Welcome to Keygen, #{account.name}!"
    end
  end
end
