# frozen_string_literal: true

module Api::V1::Users::Relationships
  class SecondFactorsController < Api::V1::BaseController
    prepend_before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

     # GET /users/1/second-factors
    def index
      @second_factors = policy_scope apply_scopes(@user.second_factors)
      authorize @second_factors

      render jsonapi: @second_factors
    end

    # GET /users/1/second-factors/1
    def show
      @second_factor = @user.second_factors.find params[:id]
      authorize @second_factor

      render jsonapi: @second_factor
    end

    # POST /users/1/second-factors
    def create
      @second_factor = @user.second_factors.new account: current_account
      authorize @second_factor

      if @user.second_factor_enabled?
        if !@user.verify_second_factor(second_factor_meta[:otp])
          render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' } and return
        end
      else
        if !@user.authenticate(second_factor_meta[:password])
          render_unauthorized detail: 'password must be valid', code: 'PASSWORD_INVALID', source: { pointer: '/meta/password' } and return
        end
      end

      if @second_factor.save
        CreateWebhookEventService.new(
          event: 'second-factor.created',
          account: current_account,
          resource: @second_factor
        ).execute

        render jsonapi: @second_factor, status: :created, location: v1_account_user_second_factor_url(@second_factor.account, @second_factor.user, @second_factor)
      else
        render_unprocessable_resource @second_factor
      end
    end

    # PATCH/PUT /users/1/second-factors/1
    def update
      @second_factor = @user.second_factors.find params[:id]
      authorize @second_factor

      # Verify this particular second factor (which may not be enabled yet)
      if !@second_factor.verify(second_factor_meta[:otp])
        render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' } and return
      end

      if @second_factor.update(second_factor_params)
        CreateWebhookEventService.new(
          event: @second_factor.enabled? ? 'second-factor.enabled' : 'second-factor.disabled',
          account: current_account,
          resource: @second_factor
        ).execute

        render jsonapi: @second_factor
      else
        render_unprocessable_resource @second_factor
      end
    end

    # DELETE /users/1/second-factors/1
    def destroy
      @second_factor = @user.second_factors.find params[:id]
      authorize @second_factor

      # Verify user's second factor if currently enabled
      if @user.second_factor_enabled? && !@user.verify_second_factor(second_factor_meta[:otp])
        render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' } and return
      end

      CreateWebhookEventService.new(
        event: 'second-factor.deleted',
        account: current_account,
        resource: @second_factor
      ).execute

      @second_factor.destroy
    end

    private

    def set_user
      @user = FindByAliasService.new(current_account.users, params[:user_id], aliases: :email).call
      authorize @user, :show?

      Keygen::Store::Request.store[:current_resource] = @user
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash, optional: true do
          param :type, type: :string, inclusion: %w[second-factor second-factors secondFactor secondFactors second_factor second_factors]
        end
        param :meta, type: :hash do
          param :password, type: :string, optional: true
          param :otp, type: :string, optional: true
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[second-factor second-factors secondFactor secondFactors second_factor second_factors]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :enabled, type: :boolean
          end
        end
        param :meta, type: :hash do
          param :otp, type: :string
        end
      end

      on :destroy do
        param :meta, type: :hash, optional: true do
          param :otp, type: :string
        end
      end
    end
  end
end
