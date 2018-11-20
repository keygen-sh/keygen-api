module Api::V1::Users::Actions
  class PasswordController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!, only: [:update_password]
    before_action :set_user, only: [:update_password, :reset_password]

    # POST /users/1/update-password
    def update_password
      authorize @user

      if @user.try(:authenticate, password_params[:meta][:old_password])
        if @user.update(password: password_params[:meta][:new_password])
          render jsonapi: @user
        else
          render_unprocessable_entity detail: "failed to update password", source: {
            pointer: "/data/attributes/password" }
        end
      else
        render_unauthorized detail: "is not valid", source: {
          pointer: "/meta/oldPassword" }
      end
    end

    # POST /users/1/reset-password
    def reset_password
      skip_authorization

      if @user.compare_hashed_token(:password_reset_token, password_params[:meta][:password_reset_token], version: "v1")

        if @user.password_reset_sent_at < 24.hours.ago
          render_unauthorized detail: "is expired", source: {
            pointer: "/meta/passwordResetToken" } and return
        end

        if @user.update(password: password_params[:meta][:new_password], password_reset_token: nil, password_reset_sent_at: nil)
          render jsonapi: @user
        else
          render_unprocessable_resource @user
        end
      else
        render_unauthorized detail: "is not valid", source: {
          pointer: "/meta/passwordResetToken" }
      end
    end

    private

    def set_user
      @user =
        if params[:id] =~ UUID_REGEX
          current_account.users.find_by id: params[:id]
        else
          current_account.users.find_by email: params[:id].downcase
        end

      raise Keygen::Error::NotFoundError.new(model: User.name, id: params[:id]) if @user.nil?
    end

    typed_parameters do
      options strict: true

      on :update_password do
        param :meta, type: :hash do
          param :old_password, type: :string
          param :new_password, type: :string
        end
      end

      on :reset_password do
        param :meta, type: :hash do
          param :password_reset_token, type: :string
          param :new_password, type: :string
        end
      end
    end
  end
end
