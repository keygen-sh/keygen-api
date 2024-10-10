# frozen_string_literal: true

class StdoutMailerPreview < ActionMailer::Preview
  def issue_0
    StdoutMailer.issue_zero(subscriber: User.first)
  end

  def issue_1
    StdoutMailer.issue_one(subscriber: User.first)
  end

  def issue_2
    StdoutMailer.issue_two(subscriber: User.first)
  end

  def issue_3
    StdoutMailer.issue_three(subscriber: User.first)
  end

  def issue_4
    StdoutMailer.issue_four(subscriber: User.first)
  end

  def issue_5
    StdoutMailer.issue_five(subscriber: User.first)
  end

  def issue_6
    StdoutMailer.issue_six(subscriber: User.first)
  end

  def issue_7
    StdoutMailer.issue_seven(subscriber: User.first)
  end

  def issue_8
    StdoutMailer.issue_eight(subscriber: User.first)
  end

  def issue_9
    StdoutMailer.issue_nine(subscriber: User.first)
  end
end
