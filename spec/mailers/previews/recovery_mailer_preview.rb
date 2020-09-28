# frozen_string_literal: true

class RecoveryMailerPreview < ActionMailer::Preview
  def recover_accounts_for_email
    RecoveryMailer.recover_accounts_for_email email: User.first.email
  end
end
