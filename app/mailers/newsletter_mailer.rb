# frozen_string_literal: true

class NewsletterMailer < ApplicationMailer
  default from: 'Zeke at Keygen <zeke@keygen.sh>'

  def november_2021
    active_accounts = Account.select(:id)
                             .joins(:billing, :request_logs)
                             .where(billings: { state: %i[subscribed trialing pending] })
                             .where('request_logs.created_at > ?', 90.days.ago)
                             .group('accounts.id')
                             .having('count(request_logs.id) > 0')

    active_admins = User.where(account_id: active_accounts, unsubscribed_from_stdout_at: nil)
                        .with_roles(:admin, :developer)
                        .uniq(&:email)

    active_admins.map do |admin|
      unsubscribe_link = stdout_unsubscribe_url(
        Base64.urlsafe_encode64(admin.email),
        protocol: 'https',
        host: 'stdout.keygen.sh',
      )

      mail(
        content_type: 'text/plain',
        email: admin.email,
        subject: "November in review -- what's new in Keygen",
        body: <<~TXT
          Hey -- long time no talk! Zeke here, founder of Keygen.

          I'm going to be trying something new -- a bi-weekly/monthly newsletter covering "what's new" in Keygen.
          It was recently brought to my attention that I don't do a good job of surfacing new updates to Keygen
          customers, so I hope that this changes that. If you don't want to receive marketing emails like this,
          you can opt-out by following this link (#{unsubscribe_link}).

          To kick things off, let's talk software distribution --

          ## Keygen Dist v2

          A few months back, we rolled out a brand new version of our distribution API. We made the decision to
          build a better version from the ground up -- one that is fully integrated into our flagship software
          licensing API. This has been a huge goal of mine, really, since I first wrote the prototype for the
          old distribution API in Go. The new API is now available at api.keygen.sh.

          We've deprecated our older distribution API, dist.keygen.sh. It will continue to be available, but
          we recommend using our new API for all new product development.

          Link: https://keygen.sh/docs/api/releases/

          ## Go SDK

          With the launch of our new distribution API, I really wanted to start focusing on SDKs. We recently
          rolled out our first SDK, for Go. With it, you can add license validation, activation, and automatic
          upgrades to any Go application.

          We're currently working on other SDKs as well, for Node, Swift, and C#. Let us know if you have any
          specific requests for an SDK! We're going to be focusing on these a lot next year.

          Link: https://github.com/keygen-sh/keygen-go

          Next up, let's talk command line --

          ## Keygen CLI

          We just recently rolled out the beta of our new Keygen CLI. You can use it to sign and publish new
          software releases to the new aforementioned distribution API. Keygen's CLI itself is published
          using the CLI, and it utilizes our Go SDK for automatic upgrades, all backed by Keygen's new
          distribution API (it's dogfooding all the way down!)

          Docs: https://keygen.sh/docs/cli/

          --

          Well, that's it for this first newsletter. Let me know if you have any feedback for me. We're going
          to make 2022 a great year -- complete with a brand new, much needed, UI overhaul (including a
          highly-requested *customer-facing* portal!)

          Thank you so much for your support!

          --
          Zeke, Founder <https://keygen.sh>

          (You're receiving this email because you signed up for a Keygen account. If you don't find this
          email useful, you can unsubscribe here: #{unsubscribe_link})
        TXT
      )
    end
  end
end
