# frozen_string_literal: true

module Api::V1::Users::Relationships
  class SecondFactorsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    authorize :user

    def index
      second_factors = apply_pagination(authorized_scope(apply_scopes(user.second_factors)))
      authorize! second_factors,
        with: Users::SecondFactorPolicy

      render jsonapi: second_factors
    end

    def show
      second_factor = user.second_factors.find(params[:id])
      authorize! second_factor,
        with: Users::SecondFactorPolicy

      render jsonapi: second_factor
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, optional: true do
        param :type, type: :string, inclusion: { in: %w[second-factor second-factors secondFactor secondFactors second_factor second_factors] }
      end
      param :meta, type: :hash do
        param :password, type: :string, optional: true
        param :otp, type: :string, optional: true
      end
    }
    def create
      second_factor = user.second_factors.new(account: current_account)
      authorize! second_factor,
        with: Users::SecondFactorPolicy

      if user.second_factor_enabled?
        if !user.verify_second_factor(second_factor_meta[:otp])
          render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' } and return
        end
      else
        if !user.authenticate(second_factor_meta[:password])
          render_unauthorized detail: 'password must be valid', code: 'PASSWORD_INVALID', source: { pointer: '/meta/password' } and return
        end
      end

      if second_factor.save
        BroadcastEventService.call(
          event: 'second-factor.created',
          account: current_account,
          resource: second_factor
        )

        render jsonapi: second_factor, status: :created, location: v1_account_user_second_factor_url(second_factor.account, second_factor.user, second_factor)
      else
        render_unprocessable_resource second_factor
      end
    end

     typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[second-factor second-factors secondFactor secondFactors second_factor second_factors] }
        param :id, type: :uuid, optional: true, noop: true
        param :attributes, type: :hash do
          param :enabled, type: :boolean
        end
      end
      param :meta, type: :hash do
        param :otp, type: :string
      end
    }
    def update
      second_factor = user.second_factors.find(params[:id])
      authorize! second_factor,
        with: Users::SecondFactorPolicy

      # Verify this particular second factor (which may not be enabled yet)
      if !second_factor.verify(second_factor_meta[:otp])
        render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' } and return
      end

      if second_factor.update(second_factor_params)
        BroadcastEventService.call(
          event: second_factor.enabled? ? 'second-factor.enabled' : 'second-factor.disabled',
          account: current_account,
          resource: second_factor
        )

        render jsonapi: second_factor
      else
        render_unprocessable_resource second_factor
      end
    end

    typed_params {
      format :jsonapi

      param :meta, type: :hash, optional: true do
        param :otp, type: :string
      end
    }
    def destroy
      second_factor = user.second_factors.find(params[:id])
      authorize! second_factor,
        with: Users::SecondFactorPolicy

      # Verify user's second factor if currently enabled
      if user.second_factor_enabled? && !user.verify_second_factor(second_factor_meta[:otp])
        render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' } and return
      end

      BroadcastEventService.call(
        event: 'second-factor.deleted',
        account: current_account,
        resource: second_factor
      )

      second_factor.destroy
    end

    private

    attr_reader :user

    def set_user
      scoped_users = authorized_scope(current_account.users)

      @user = FindByAliasService.call(scoped_users, id: params[:user_id], aliases: :email)

      Current.resource = user
    end
  end
end
