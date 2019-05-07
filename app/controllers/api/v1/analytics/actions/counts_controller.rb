module Api::V1::Analytics::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    # GET /analytics/actions/count
    def count
      authorize Metric # TODO(ezekg) Should this be an Analytics model?

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        licenses = current_account.licenses.count
        machines = current_account.machines.count
        users = current_account.users.count

        {
          meta: {
            licenses: licenses,
            machines: machines,
            users: users,
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