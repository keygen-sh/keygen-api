class AccountMailer < ApplicationMailer

  def payment_method_missing(account)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Your account is still missing payment details"
    end
  end

  def payment_failed(account)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Your payment failed"
    end
  end

  def failed_payment(account)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Your payment failed"
    end
  end

  def subscription_canceled(account)
    @account = account

    account.admins.each do |admin|
      @user = admin

      mail to: admin.email, subject: "Your subscription has been canceled"
    end
  end
end
