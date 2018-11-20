class ReportMailerPreview < ActionMailer::Preview
  def request_limits
    ReportMailer.request_limits date: Date.yesterday, reports: []
  end
end
