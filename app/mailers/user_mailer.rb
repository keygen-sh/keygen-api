# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: "Keygen <noreply@keygen.sh>"
  default precedence: 'urgent'

  layout "user_mailer"

  def password_reset(user:, token:)
    @user    = user
    @account = @user.account
    @expiry  = @user.password_reset_sent_at + 24.hours
    @token   = [@account.id.remove('-'), @user.id.remove('-'), token].join('.')

    subject = if @user.password?
                "Password reset requested for your #{@account.name} account"
              else
                "Set a password for your #{@account.name} account"
              end

    mail to: user.email, reply_to: @account.email, subject: subject
  end
end
