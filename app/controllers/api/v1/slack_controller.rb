# frozen_string_literal: true

module Api::V1
  class SlackController < Api::V1::BaseController
    skip_verify_authorized

    def callback
      Slack::Event.verify_signature!(request, signing_secret: SLACK_SIGNING_SECRET)

      case params
      in type: 'shared_channel_invite_accepted', channel: { id: channel_id }, accepting_user: { team_id: }
        account = Account.find_by(slack_channel_id: channel_id)
        return if
          account.nil?

        # send us an invite once the customer accepts the invite
        slack = Slack::Client.new(token: SLACK_TOKEN)

        slack.share_channel(
          email: SLACK_ADMIN_EMAIL,
          channel_id:,
        )

        account.update(
          slack_accepted_at: Time.current,
          slack_team_id: team_id,
        )
      in type: 'url_verification'
        # ack
      else
        head :unprocessable_content and return
      end

      render plain: params[:challenge]
    rescue Slack::SignatureError
      head :bad_request
    end
  end
end
