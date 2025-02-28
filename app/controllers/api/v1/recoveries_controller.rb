# frozen_string_literal: true

module Api::V1
  class RecoveriesController < Api::V1::BaseController
    skip_verify_authorized

    typed_params {
      format :jsonapi

      param :meta, type: :hash do
        param :type, type: :string, inclusion: { in: %w[account] }
        param :email, type: :string
      end
    }
    def recover
      case recovery_meta
      in type: 'account', email:
        mailer = RecoveryMailer.recover_accounts_for_email(email:)
        mailer.deliver_later
      end
    end
  end
end
