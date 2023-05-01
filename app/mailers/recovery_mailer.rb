# frozen_string_literal: true

class RecoveryMailer < ApplicationMailer
  layout "recovery_mailer"

  def recover_accounts_for_email(email:)
    @users = User.preload(:account)
                 .joins(:role)
                 .where(email: email.to_s.downcase, roles: { name: [:admin, :developer, :read_only, :sales_agent, :support_agent] })
                 .where('EXISTS (SELECT null FROM "accounts" WHERE "accounts"."id" = "users"."account_id")')
    return unless @users.any?

    mail to: email, subject: "Keygen account recovery for #{email}"
  end
end
