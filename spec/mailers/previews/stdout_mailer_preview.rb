# frozen_string_literal: true

class StdoutMailerPreview < ActionMailer::Preview
  def issue_zero
    StdoutMailer.issue_zero(subscriber: User.first)
  end
end
