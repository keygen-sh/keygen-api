class ReportMailer < ApplicationMailer
  default from: 'Keygen Reports <support@keygen.sh>', to: 'zeke+reports@keygen.sh'
  layout 'report_mailer'

  def request_limits(date:, reports:)
    @date = date
    @reports = reports

    mail subject: "Request limits report for #{date.strftime '%m/%d/%Y'}"
  end
end
