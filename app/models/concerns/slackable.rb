# frozen_string_literal: true

module Slackable
  extend ActiveSupport::Concern

  SLACK_INVITE_TZ = ENV.fetch('SLACK_INVITE_TZ') { 'Central Time (US & Canada)' }

  included do
    attr_accessor :skip_slack_invite

    after_commit :send_slack_invite, on: :create,
      unless: -> { skip_slack_invite? || free_or_disposable_domain? }, # skip non-work accounts
      if: -> { Keygen.cloud? }
  end

  def skip_slack_invite? = !!skip_slack_invite
  def send_slack_invite
    now = Time.now.in_time_zone(SLACK_INVITE_TZ)

    t  = now.beginning_of_day
    t  = t.next_weekday if t.on_weekend? # only weekdays
    t += rand(9..17.0).hours             # only 9am-5pm
    t  = t.next_weekday if t.past?       # only future

    SlackInviteWorker.perform_at(t, id)
  end
end
