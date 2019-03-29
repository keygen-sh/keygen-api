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
      next unless request_count > 0

      admin = account.admins.first
      plan = account.plan
      request_limit = plan.max_reqs
      request_limit_exceeded = (request_count > request_limit * 1.3) rescue false
      report = OpenStruct.new(
        request_count: request_count,
        request_limit: request_limit,
        account: account,
        admin: admin,
        plan: plan
      )

      if request_limit_exceeded && !account.trialing_or_free_tier?
        AccountMailer.request_limit_exceeded(account: account, plan: plan, request_count: request_count, request_limit: request_limit).deliver_later
      end

      reports << report
    end

    ReportMailer.request_limits(date: date, reports: reports).deliver_now
  end
end
