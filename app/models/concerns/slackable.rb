# frozen_string_literal: true

module Slackable
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_slack_invite

    after_commit :send_slack_invite, on: :create,
      unless: -> { skip_slack_invite? || free_or_disposable_domain? }, # skip non-work accounts
      if: -> { Keygen.multiplayer? }
  end

  def skip_slack_invite? = !!skip_slack_invite
  def send_slack_invite
    SlackInviteWorker.perform_in(
      rand(1..4).hours, # random delay
      id,
    )
  end
end
