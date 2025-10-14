# frozen_string_literal: true

class SlackInviteWorker < BaseWorker
  sidekiq_options retry: false

  def perform(account_id)
    account = Account.find(account_id)
    return if
      account.free_or_disposable_domain?

    admin = account.admins.last
    return unless
      admin.email_domain_has_mx?

    # create a private channel
    channel_prefix = admin.email_host.split('.').first # second-level domain e.g. keygen.sh -> keygen, slack.com -> slack
    channel_id     = slack.create_channel(
      name: "#{channel_prefix}-keygen",
    )

    # send a connect invite
    account.admins.unordered.find_each do |admin|
      next if
        admin.free_or_disposable_email?

      slack.share_channel(
        email: admin.email,
        channel_id:,
      )
    end

    account.update(
      slack_invited_at: Time.current,
      slack_channel_id: channel_id,
    )
  end

  private

  def slack = Slack::Client.new(token: SLACK_TOKEN)
end
