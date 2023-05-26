# frozen_string_literal: true

module Api::V1::Analytics::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    def count
      authorize! to: :show?, with: Accounts::AnalyticsPolicy

      json = Rails.cache.fetch(cache_key_for(:count), expires_in: 10.minutes, race_condition_ttl: 1.minute) do
        active_licensed_users = current_account.active_licensed_user_count
        active_licenses = current_account.licenses.active.count
        total_licenses = current_account.licenses.count
        total_machines = current_account.machines.count
        total_users = current_account.users.with_roles(:user).count

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

    def top_licenses_by_volume
      authorize! to: :show?, with: Accounts::AnalyticsPolicy

      json = Rails.cache.fetch(cache_key_for(:top_licenses_by_volume), expires_in: 10.minutes, race_condition_ttl: 1.minute) do
        start_date = 13.days.ago.beginning_of_day
        end_date   = Time.current

        conn = ActiveRecord::Base.connection
        rows = conn.execute(
          RequestLog.sanitize_sql([<<~SQL, account_id: current_account.id, start_date:, end_date:])
            SELECT
              "request_logs"."resource_id" AS license_id,
              COUNT(*) AS count
            FROM
              "request_logs"
            WHERE
              "request_logs"."account_id" = :account_id AND
              "request_logs"."resource_type" = 'License' AND
              "request_logs"."resource_id" IS NOT NULL AND
              (
                "request_logs"."created_at" >= :start_date AND
                "request_logs"."created_at" <= :end_date
              )
            GROUP BY
              "request_logs"."resource_id"
            ORDER BY
              count DESC
            LIMIT
              10
          SQL
        )

        {
          meta: rows.map { |r| r.slice('license_id', 'count').transform_keys { |k| k.camelize(:lower) } },
        }
      end

      render json: json
    end

    def top_urls_by_volume
      authorize! to: :show?, with: Accounts::AnalyticsPolicy

      json = Rails.cache.fetch(cache_key_for(:top_urls_by_volume), expires_in: 10.minutes, race_condition_ttl: 1.minute) do
        start_date = 13.days.ago.beginning_of_day
        end_date   = Time.current

        conn = ActiveRecord::Base.connection
        rows = conn.execute(
          RequestLog.sanitize_sql([<<~SQL, account_id: current_account.id, start_date:, end_date:])
            SELECT
              "request_logs"."method" AS method,
              "request_logs"."url" AS url,
              COUNT(*) AS count
            FROM
              "request_logs"
            WHERE
              "request_logs"."account_id" = :account_id AND
              "request_logs"."method" IS NOT NULL AND
              "request_logs"."url" IS NOT NULL AND
              (
                "request_logs"."created_at" >= :start_date AND
                "request_logs"."created_at" <= :end_date
              )
            GROUP BY
              "request_logs"."method",
              "request_logs"."url"
            ORDER BY
              count DESC
            LIMIT
              10
          SQL
        )

        {
          meta: rows.map { |r| r.slice('method', 'url', 'count') },
        }
      end

      render json: json
    end

    def top_ips_by_volume
      authorize! to: :show?, with: Accounts::AnalyticsPolicy

      json = Rails.cache.fetch(cache_key_for(:top_ips_by_volume), expires_in: 10.minutes, race_condition_ttl: 1.minute) do
        start_date = 13.days.ago.beginning_of_day
        end_date   = Time.current

        conn = ActiveRecord::Base.connection
        rows = conn.execute(
          RequestLog.sanitize_sql([<<~SQL, account_id: current_account.id, start_date:, end_date:])
            SELECT
              "request_logs"."ip" AS ip,
              COUNT(*) AS count
            FROM
              "request_logs"
            WHERE
              "request_logs"."account_id" = :account_id AND
              "request_logs"."ip" IS NOT NULL AND
              (
                "request_logs"."created_at" >= :start_date AND
                "request_logs"."created_at" <= :end_date
              )
            GROUP BY
              "request_logs"."ip"
            ORDER BY
              count DESC
            LIMIT
              10
          SQL
        )

        {
          meta: rows.map { |r| r.slice('ip', 'count') },
        }
      end

      render json: json
    end

    private

    def cache_key_for(action)
      [:analytics, current_account.id, action, CACHE_KEY_VERSION].join ":"
    end
  end
end
