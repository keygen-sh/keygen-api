# frozen_string_literal: true

class RequestLimitsReportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cron, unique: :until_executed

  def perform
    date = Date.yesterday
    reports = []

    active_states = %w[subscribed trialing pending]
    start_date = date.beginning_of_day
    end_date = date.end_of_day

    Account.includes(:billing, :plan).where(billings: { state: active_states }).find_each do |account|
      request_count = account.request_logs.where(created_at: (start_date..end_date)).count
      if request_count == 0
        next unless account.trialing_or_free_tier? &&
                    account.created_at > 2.months.ago

        request_count_for_week = account.request_logs.where('request_logs.created_at > ?', 1.week.ago).count
        next if request_count_for_week > 0

        if account.last_low_activity_lifeline_sent_at.nil?
          account.touch(:last_low_activity_lifeline_sent_at)

          PlaintextMailer.low_activity_lifeline(account: self).deliver_later(wait: 42.minutes)
        end

        next
      end

      admin = account.admins.first
      plan = account.plan

      request_limit = plan.max_reqs

      admin_count = account.users.roles(:admin, :developer, :sales_agent, :support_agent).count
      admin_limit = plan.max_admins

      product_count = account.products.count
      product_limit = plan.max_products

      active_licensed_user_count = account.active_licensed_user_count
      license_count = account.licenses.count
      license_limit = plan.max_licenses ||
                      plan.max_users

      report = OpenStruct.new(
        request_count: request_count,
        request_limit: request_limit,
        active_licensed_user_count: active_licensed_user_count,
        license_count: license_count,
        license_limit: license_limit,
        product_count: product_count,
        product_limit: product_limit,
        admin_count: admin_count,
        admin_limit: admin_limit,
        account: account,
        admin: admin,
        plan: plan
      )

      license_limit_exceeded = (active_licensed_user_count > license_limit * 1.1) rescue false
      request_limit_exceeded = (request_count > request_limit * 1.3) rescue false

      # TODO(ezekg) Uncomment when we add related account stat widgets to the admin dashboard
      # TODO(ezekg) Ensure active subscription i.e. not canceled
      # # Only send on Mondays to limit inbox noise for accounts that are currently
      # # over their license limit but don't upgrade right away
      # if Date.today.monday? && license_limit_exceeded
      #   AccountMailer.license_limit_exceeded(account: account, plan: plan, license_count: request_count, license_limit: request_limit).deliver_later
      # end

      if request_limit_exceeded
        AccountMailer.request_limit_exceeded(account: account, plan: plan, request_count: request_count, request_limit: request_limit).deliver_later
      end

      reports << report
    end

    ReportMailer.request_limits(date: date, reports: reports).deliver_now
  end
end
