# frozen_string_literal: true

class StdoutMailerPreview < ActionMailer::Preview
  def issue_0
    StdoutMailer.issue_zero(subscriber: User.first)
  end

  def issue_1
    StdoutMailer.issue_one(subscriber: User.first)
  end
end
