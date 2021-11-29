# frozen_string_literal: true

class StdoutMailerPreview < ActionMailer::Preview
  def issue_one
    StdoutMailer.issue_one
  end
end
