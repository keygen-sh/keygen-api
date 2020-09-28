# frozen_string_literal: true

module Api::V1
  class RecoveriesController < Api::V1::BaseController

    # POST /recover
    def recover
      skip_authorization

      case recovery_params[:meta][:type]
      when 'account'
        mailer = RecoveryMailer.recover_accounts_for_email email: recovery_params[:meta][:email]
        mailer.deliver_now
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
