# frozen_string_literal: true

module Api::V1::Users::Actions
  class PasswordController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate!, only: %i[update]
    before_action :set_user, only: %i[update reset]

    authorize :user

    typed_params {
      format :jsonapi

      param :meta, type: :hash do
        param :old_password, type: :string
        param :new_password, type: :string
      end
    }
    def update
      authorize! user,
        with: Users::PasswordPolicy

      if user.password? && user.authenticate(password_meta[:old_password])
        if user.update(password: password_meta[:new_password], password_reset_token: nil, password_reset_sent_at: nil)
          user.revoke_tokens!(except: current_token)

          render jsonapi: user
        else
          render_unprocessable_resource user
        end
      else
        render_unauthorized source: { pointer: '/meta/oldPassword' },
                            detail: 'is not valid'
      end
    end

    typed_params {
      format :jsonapi

      param :meta, type: :hash do
        param :password_reset_token, type: :string
        param :new_password, type: :string
      end
    }
    def reset
      authorize! user,
        with: Users::PasswordPolicy

      # Raise 404 so that we don't leak user information since we're
      # not scoping with authorized_scope() for this action.
      raise Keygen::Error::NotFoundError.new(model: User.name, id: params[:id]) unless
        user.compare_hashed_token(:password_reset_token, password_meta[:password_reset_token])

      return render_unauthorized(detail: 'is expired', source: { pointer: '/meta/passwordResetToken' }) if
        user.password_reset_sent_at < 24.hours.ago

      if user.update(password: password_meta[:new_password], password_reset_token: nil, password_reset_sent_at: nil)
        user.revoke_tokens!

        render jsonapi: user
      else
        render_unprocessable_resource user
      end
    end

    private

    attr_reader :user

    def set_user
      # Since our reset tokens are hashed, we can't do a lookup on token. So
      # first, we need to query the unscoped user, then compare the token.
      # On invalid token, we'll raise a 404 to prevent user enumeration.
      scoped_users = case action_name.to_sym
                     when :update
                       authorized_scope(current_account.users)
                     else
                       current_account.users
                     end

      @user = FindByAliasService.call(scoped_users, id: params[:id], aliases: :email)

      Current.resource = user
    end
  end
end
