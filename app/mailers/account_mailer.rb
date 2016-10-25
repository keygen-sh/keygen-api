class AccountMailer < ApplicationMailer

  def card_needed_reminder(account)
    @account = account

    account.admins do |admin|
      @user = admin

      mail to: admin.email, subject: "Your trial is ending soon: payment details needed"
    end
  end

  def payment_failed(account)
    @account = account

    account.admins do |admin|
      @user = admin

      mail to: admin.email, subject: "Your payment failed"
    end
  end

  def failed_payment(account)
    @account = account

    account.admins do |admin|
      @user = admin

      mail to: admin.email, subject: "Your payment failed"
    end
  end
end
