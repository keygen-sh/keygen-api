# frozen_string_literal: true

module Api::V1::Analytics::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    # GET /analytics/actions/count
    def count
      authorize Metric

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        active_licensed_users = current_account.active_licensed_user_count
        active_licenses = current_account.licenses.active.count
        total_licenses = current_account.licenses.count
        total_machines = current_account.machines.count
        total_users = current_account.users.count

        {
          meta: {
            activeLicensedUsers: active_licensed_users,
            activeLicenses: active_licenses,
            totalLicenses: total_licenses,
            totalMachines: total_machines,
            totalUsers: total_users,
          }
        }
      end

      render json: json
    end

    private

    def cache_key
      [:analytics, current_account.id].select(&:present?).join ":"
    end
  end
end