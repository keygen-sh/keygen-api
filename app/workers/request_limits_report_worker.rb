# frozen_string_literal: true

class RequestLimitsReportWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    date = Date.yesterday

    active_states = %w[subscribed trialing pending]
    start_date = date.beginning_of_day
    end_date = date.end_of_day

    Account.includes(:billing, :plan).where(billings: { state: active_states }).unordered.find_each do |account|
      Keygen.logger.info "[workers.request-limits-report] Generating report: account_id=#{account.id}"

      admin = account.admins.last
      plan  = account.plan

      request_count = account.request_logs.where(created_at: (start_date..end_date)).count
      request_limit = plan.max_reqs

      admin_count = account.users.with_roles(:admin, :developer, :read_only, :sales_agent, :support_agent).count
      admin_limit = plan.max_admins

      product_count = account.products.count
      product_limit = plan.max_products

      active_licensed_user_count = account.active_licensed_user_count
      license_count = account.licenses.count
      license_limit = plan.max_licenses ||
                      plan.max_users

      begin
        # Only send once a week to limit inbox noise for accounts that are currently
        # over their license limit but don't upgrade right away
        license_limit_reached = (active_licensed_user_count >= license_limit) rescue false
        license_limit_exceeded = (active_licensed_user_count > license_limit * 1.1) rescue false
        should_send_license_limit_notification =
          (account.last_license_limit_exceeded_sent_at.nil? || account.last_license_limit_exceeded_sent_at < 1.week.ago) &&
          ((account.trialing_or_free? && license_limit_reached) || (account.paid? && license_limit_exceeded))

        if should_send_license_limit_notification
          account.touch(:last_license_limit_exceeded_sent_at)

          Keygen.logger.info "[workers.request-limits-report] Sending license limit exceeded email: account_id=#{account.id}"

          AccountMailer.license_limit_exceeded(account: account, plan: plan, license_count: active_licensed_user_count, license_limit: license_limit).deliver_later
        end

        # Send once per day if there was a daily request limit overage
        request_limit_exceeded = (request_count > request_limit * 1.3) rescue false
        should_send_request_limit_notification =
          (account.last_request_limit_exceeded_sent_at.nil? || account.last_request_limit_exceeded_sent_at < 23.hours.ago) &&
          request_limit_exceeded

        if should_send_request_limit_notification
          account.touch(:last_request_limit_exceeded_sent_at)

          Keygen.logger.info "[workers.request-limits-report] Sending request limit exceeded email: account_id=#{account.id}"

          AccountMailer.request_limit_exceeded(account: account, plan: plan, request_count: request_count, request_limit: request_limit).deliver_later
        end
      rescue => e
        account.touch(:last_license_limit_exceeded_sent_at, :last_request_limit_exceeded_sent_at) rescue nil

        Keygen.logger.exception(e)
      end
    end
  end
end
