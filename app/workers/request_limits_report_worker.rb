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

      request_limit = account.plan.max_reqs
      admin = account.admins.first

      reports << OpenStruct.new(
        request_count: request_count,
        request_limit: request_limit,
        account: account,
        admin: admin
      )
    end

    ReportMailer.request_limits(date: date, reports: reports).deliver_now
  end
end
