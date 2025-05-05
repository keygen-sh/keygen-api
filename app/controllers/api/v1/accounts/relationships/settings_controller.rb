# frozen_string_literal: true

module Api::V1::Accounts::Relationships
  class SettingsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_setting, only: %i[show update destroy]

    def index
      settings = apply_pagination(authorized_scope(apply_scopes(current_account.settings)))
      authorize! settings,
        with: Accounts::SettingPolicy

      render jsonapi: settings
    end

    def show
      authorize! setting,
        with: Accounts::SettingPolicy

      render jsonapi: setting
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[setting settings] }
        param :attributes, type: :hash do
          param :key, type: :string, transform: -> k, v { [k, v.underscore] }
          param :value, type: :any
        end
      end
    }
    def create
      setting = current_account.settings.new(**setting_params)
      authorize! setting,
        with: Accounts::SettingPolicy

      if setting.save
        BroadcastEventService.call(
          event: 'account.settings.created',
          account: current_account,
          resource: setting,
        )

        render jsonapi: setting, status: :created, location: v1_account_setting_url(setting.account_id, setting)
      else
        render_unprocessable_resource setting
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[setting settings] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :value, type: :any
        end
      end
    }
    def update
      authorize! setting,
        with: Accounts::SettingPolicy

      if setting.update(setting_params)
        BroadcastEventService.call(
          event: 'account.settings.updated',
          account: current_account,
          resource: setting,
        )

        render jsonapi: setting
      else
        render_unprocessable_resource setting
      end
    end

    def destroy
      authorize! setting,
        with: Accounts::SettingPolicy

      BroadcastEventService.call(
        event: 'account.settings.deleted',
        account: current_account,
        resource: setting,
      )

      setting.destroy
    end

    private

    attr_reader :setting

    def set_setting
      scoped_settings = authorized_scope(current_account.settings)

      @setting = scoped_settings.find_by_alias(params[:id], aliases: %i[key])

      Current.resource = current_account
    end
  end
end
