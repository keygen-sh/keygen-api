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

      greeting = if admin.first_name?
                   "Hey, #{admin.first_name}"
                 else
                   "Hey"
                 end

      mail(
        content_type: 'text/plain',
        email: admin.email,
        subject: "Trying something new",
        body: <<~TXT
          #{greeting} -- long time no update! Zeke here, founder of Keygen.

          I'm going to be trying something new -- a monthly-ish newsletter covering "what's new" in Keygen. It
          was recently brought to my attention that I don't do a good job of surfacing new updates to Keygen
          customers, so I hope this changes that. If you don't want to receive marketing emails like this,
          you can opt-out anytime by following this link: #{unsubscribe_link}

          To kick things off, let's talk software distribution --

          ## Keygen Dist v2

          A few months back, we rolled out a brand new version of our distribution API. We made the decision to
          build a better version from the ground up -- one that is fully integrated into our flagship software
          licensing API. This has been a huge goal of mine, really, since I first wrote the prototype for the
          old distribution API in Go. The new API is now available at api.keygen.sh.

          Some cool features of Dist v2:

            - You can add entitlement constraints to releases, ensuring that only users that possess a license
              with those entitlements can access the release. E.g. a popular use case is locking a license to
              a specific major version of a product until they purchase an upgrade. This can be accomplished
              using entitlement constraints, with a V1 and V2 entitlement, respectively.
            - You can set a product's "distribution strategy", allowing you to either distribute your product
              OPENly to anybody, no license required, or only to LICENSED users (the default). This really
              opens up doors for Keygen to support a wider variety of business models, such as freemium
              distribution as well as open source.

          We've deprecated our older distribution API, dist.keygen.sh. It'll continue to be available, but we
          recommend using our new API for all new product development.

          Docs: https://keygen.sh/docs/api/releases/

          ## Go SDK

          With the launch of our new distribution API, I really wanted to start focusing on SDKs. We recently
          rolled out our first SDK, for Go. With it, you can add license validation, activation, and automatic
          upgrades to any Go application.

          We're currently working on other SDKs as well, for Node, Swift, and C#. Up next will be a macOS SDK,
          written in Swift. Let me know if you have any specific requests for an SDK!

          Source: https://github.com/keygen-sh/keygen-go

          Next up, let's talk command line --

          ## Keygen CLI

          We just recently rolled out the beta of our new Keygen CLI. You can use it to sign and publish new
          software releases to the new aforementioned distribution API. Keygen's CLI itself is published
          using the CLI, and it utilizes our Go SDK for automatic upgrades, all backed by Keygen's new
          distribution API (it's dogfooding all the way down!)

          To install the CLI, you can run this quick install script:

            curl -sSL https://get.keygen.sh/keygen/cli/install.sh | sh

          The install script will auto-detect your platform and install the approriate binary. You can, of
          course, install manually by visiting the docs, linked below.

          Source: https://github.com/keygen-sh/keygen-cli
          Docs: https://keygen.sh/docs/cli/

          --

          Well, that's it for this first newsletter. Let me know if you have any feedback for me. We're going
          to make 2022 a great year -- complete with a brand new, much needed, UI overhaul (including a
          highly-requested *customer-facing* portal!)

          Thank you so much for your support!

          Until next time,

          --
          Zeke, Founder <https://keygen.sh>

          (You're receiving this email because you signed up for a Keygen account. If you don't find this
          email useful, you can unsubscribe here: #{unsubscribe_link})
        TXT
      )
    end
  end
end
