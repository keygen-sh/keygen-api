# frozen_string_literal: true

class AccountMailerPreview < ActionMailer::Preview

  def request_limit_exceeded
    report = OpenStruct.new(
      request_count: 16_384,
      request_limit: 10_000,
      account: account,
      plan: account.plan
    )

    AccountMailer.request_limit_exceeded(
      account: report.account,
      plan: report.plan,
      request_count: report.request_count,
      request_limit: report.request_limit
    )
  end

  def license_limit_exceeded
    report = OpenStruct.new(
      license_count: 16_384,
      license_limit: 10_000,
      account: account,
      plan: account.plan
    )

    AccountMailer.license_limit_exceeded(
      account: report.account,
      plan: report.plan,
      license_count: report.license_count,
      license_limit: report.license_limit
    )
  end

  def payment_failed
    invoice = { hosted_invoice_url: 'https://pay.stripe.com/invoice/acct_17LRySBuIJAzxZqV/invst_HlevM2pFfEVxU1LkG2i8sdXyv2w7ftK' }

    AccountMailer.payment_failed account: account, invoice: invoice
  end

  def subscription_canceled
    AccountMailer.subscription_canceled account: account
  end

  def welcome
    AccountMailer.welcome account: account
  end

  private

  def account
    @account ||= Account.first
  end
end
