module Api::V1::Accounts::Actions
  class InvitationsController < Api::V1::BaseController
    before_action :set_account, only: [:accept]

    # POST /accounts/1/actions/accept-invitation
    def accept
      skip_authorization

      if @account.compare_encrypted_token(:invite_token, invitation_params[:meta][:invite_token])
        if @account.beta_user?
          render_conflict detail: "has already been used", source: {
            pointer: "/meta/inviteToken" }
        elsif @account.accept_invitation!
          head :accepted
        else
          render_unprocessable_entity detail: "failed to accept invitation", source: {
            pointer: "/meta/inviteToken" }
        end
      else
        render_unprocessable_entity detail: "is not valid", source: {
          pointer: "/meta/inviteToken" }
      end
    end

    private

    def set_account
      @account = Account.find params[:id]
    end

    typed_parameters do
      options strict: true

      on :accept do
        param :meta, type: :hash do
          param :invite_token, type: :string
        end
      end
    end
  end
end
