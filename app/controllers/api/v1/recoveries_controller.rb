# frozen_string_literal: true

module Api::V1
  class RecoveriesController < Api::V1::BaseController

    # POST /recover
    def recover
      skip_authorization

      case recovery_params
      in meta: { type: 'account', email: }
        mailer = RecoveryMailer.recover_accounts_for_email(email:)
        mailer.deliver_later
      end
    end

    private

    typed_parameters do
      options strict: true

      on :recover do
        param :meta, type: :hash do
          param :type, type: :string, inclusion: %w[account]
          param :email, type: :string
        end
      end
    end
  end
end
