# frozen_string_literal: true

class StdoutMailerPreview < ActionMailer::Preview
  def issue_11 = StdoutMailer.issue_eleven(subscriber: User.first)
end
