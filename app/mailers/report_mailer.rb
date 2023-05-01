# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  default from: "Keygen Reports <#{DEFAULT_FROM_EMAIL}>", to: 'zeke+reports@keygen.sh'
  layout 'report_mailer'

  def request_limits(date:, reports:)
    @request_count = reports.map(&:request_count).sum
    @date = date
    @reports = reports
      .map do |report|
        report.request_limit_exceeded = (report.request_count > report.request_limit) rescue false
        report.license_limit_exceeded = (report.active_licensed_user_count > report.license_limit) rescue false
        report.product_limit_exceeded = (report.product_count > report.product_limit) rescue false
        report.admin_limit_exceeded = (report.admin_count > report.admin_limit) rescue false
        report
      end
      .sort_by do |report|
        [
          # NOTE(ezekg) Ruby can't sort on boolean fields
          (report.request_limit_exceeded || report.license_limit_exceeded) ? 1 : 0,
          report.request_count,
        ]
      end
      .reverse

    @free_user_count = @reports.filter { |r| r.account.plan&.free? }.size
    @paid_user_count = @reports.filter { |r| r.account.plan&.paid? }.size

    @new_accounts = Account.where(created_at: date.all_day).limit(25)
    @new_products = Product.where(created_at: date.all_day).limit(25)

    mail subject: "Request limits report for #{date.strftime '%m/%d/%Y'}"
  end
end
