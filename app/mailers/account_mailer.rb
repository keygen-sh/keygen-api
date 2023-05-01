# frozen_string_literal: true

class AccountMailer < ApplicationMailer
  layout "account_mailer"

  def request_limit_exceeded(account:, plan:, request_count:, request_limit:)
    @account = account
    @plan = plan
    @report = OpenStruct.new(
      request_count: request_count,
      request_limit: request_limit
    )

    account.technical_contacts.each do |admin|
      @user = admin

      mail to: admin.email, subject: "You've exceeded the daily API request limit of your Keygen account"
    end
  end

  def license_limit_exceeded(account:, plan:, license_count:, license_limit:)
    @account = account
    @plan = plan
    @report = OpenStruct.new(
      license_count: license_count,
      license_limit: license_limit
    )

    account.technical_contacts.each do |admin|
      @user = admin

      mail to: admin.email, subject: "You've exceeded the active licensed user limit of your Keygen account"
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

  def welcome(account:)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Warm welcome from Keygen"
    end
  end
end
