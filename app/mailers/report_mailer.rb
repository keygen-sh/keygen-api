class ReportMailer < ApplicationMailer
  default from: 'Keygen Reports <support@keygen.sh>', to: 'zeke+reports@keygen.sh'
  layout 'report_mailer'

  def request_limits(date:, reports:)
    @request_count = reports.map(&:request_count).sum
    @date = date
    @reports = reports
      .map do |report|
        report.request_limit_exceeded = (report.request_count > report.request_limit) rescue false
        report
      end
      .sort_by do |report|
        [
          # NOTE(ezekg) Ruby can't sort on boolean fields
          report.request_limit_exceeded ? 1 : 0,
          report.request_count
        ]
      end
      .reverse

    mail subject: "Request limits report for #{date.strftime '%m/%d/%Y'}"
  end
end
