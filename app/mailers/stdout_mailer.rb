# frozen_string_literal: true

class StdoutMailer < ApplicationMailer
  default from: 'Zeke at Keygen <zeke@keygen.sh>'
  default precedence: 'bulk'

  def issue_eleven(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at? || subscriber.free_or_disposable_email?

    enc_email = encrypt(subscriber.email)
    return if
      enc_email.nil?

    unsub_link = stdout_unsubscribe_url(enc_email, protocol: 'https', host: 'stdout.keygen.sh')
    greeting   = if subscriber.first_name?
                    "Hey, #{subscriber.first_name}"
                  else
                    'Hey'
                  end

    mail(
      content_type: 'text/plain',
      to: subscriber.email,
      subject: "New pricing, Slack support, custom permissions, audit logs, and SSO!",
      body: <<~TXT
        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        Zeke here, founder of Keygen. Been a bit. Quick update on what's new in Keygen, as well as what's next.

        Let's dive straight in --

        ## Keygen turns 9

        Last month, Keygen celebrated its **9th** birthday! Absolutely crazy to think about! Doesn't seem like that long, but at the same time it's hard to remember my professional life without Keygen.

        I'd like to give a special thanks to every current and past customer of Keygen. Y'all have made this a joy.

        Initial commit: https://github.com/keygen-sh/keygen-api/commit/84e8ccc35ea4accaf45d8bf529ba554650465644

        ## New pricing

        **First off: the changes discussed below are for new subscriptions only. Existing subscriptions are "grandfathered in," as always when we make these types of pricing adjustments. Just want to clarify before we get too deep into the weeds here.**

        Some of you may have already noticed (as some of y'all do), we've updated our pricing to reflect the added value we're providing now vs what we provided back in 2020, from overall platform reliability and security, to additional licensing capabilities in our licensing engine, to support for OCI/Docker, npm, Rubygems, etc. in our distribution engine.

        The new pricing has higher API request limits overall in preparation for an upcoming release around a new metering engine, allowing y'all to meter entitlement consumption, even in high-volume (which will be great for AI startups to tie into usage-based and token-based billing models).

        The pricing update will help make some of our tiers more sustainable and overtime put us into more healthy margins, which will first and foremost help facilitate growing the team from just me so that we can accomplish more and at a faster pace (and good news: already working on our first hire!)

        Keygen is still 100% bootstrapped, revenue-funded, and profitable, and I'm super proud of where it's at. The new pricing reflects my commitment to making sure Keygen can continue to grow, remain healthy, and most importantly not be limited by the output of a single person (me). It's been an incredible journey doing this solo for 9 years, but I'm ready to have a team beside me to make sure Keygen can continue to scale and meet the requirements of the new age of AI computing.

        **Once again: this pricing change *DOES NOT* affect existing customers -- y'all are "grandfathered in," so to speak, as usual when we make pricing updates!**

        (Though do note that all future downgrades/upgrades will be on the new pricing tiers moving forward, also as usual.)

        Link: https://keygen.sh/pricing/

        ## Slack support

        I want to make sure everybody using Keygen is successful, and I want to try something other than just email, so I've started offering Slack support for customers registered with a work email.

        Slack support is in addition to email support. Happy to answer questions, offer integration support, or just talk shop re: licensing/distribution/business.

        If you want a Slack invite, reply to this email and I'll send over a Connect invite to a private 1-1 channel.

        ## Custom permissions

        As part of prepping for Keygen Portal, our new UI, we've rolled out custom permissions to all customers. Your dashboard should have a new `permissions` attribute on various resources like users, licenses, and tokens.

        In addition, you should see options for configuring default permission sets for users and licenses soon under your /settings page.

        Custom permissions used to be an Ent-only feature, now it's GA'd and available on all Dev and Std tiers!

        Link: https://keygen.sh/docs/api/authorization/

        ## Audit logs

        Like custom permissions, to prep for Portal, we've also GA'd event logs, which provide a feed of everything that happens in an account. Your dashboard should have a new event logs page.

        To boot, all Std tiers have a retention period of 3 days, and all Ent tiers have a retention period of 30 days. If you'd like longer retention, reach out!

        Audit logs used to be an Ent-only feature, now GA'd! Win-win for security and observability.

        Link: https://keygen.sh/docs/api/event-logs/

        ## SAML/SSO

        Our enterprise Ent tiers now offer SAML/SSO authentication and authorization. If you're interested in upgrading and getting set up, reply to this email.

        SAML/SSO is not available on our older Ent pricing tiers, due to cost misalignment. SAML/SSO will be available in Portal.

        Link: https://keygen.sh/docs/sso/

        ## What's next

        We're hard at work on Portal, our brand new UI. Super excited to share more in the coming months (I've already shared a few early screenshots in Discord: https://keygen.sh/discord/).

        Hoping to have Portal out -- or at least in some sort of beta form -- by Q3/Q4. But this project has been long, so don't take that as a promise or hard release date just yet.

        Lastly, as mentioned, we're starting work on new metering capabilities. This will allow you to set up, consume, and enforce limits on entitlement usage.

        ## What's old

        As always, for more in-depth information on what's changed and what's new over the last few months, check out our changelog!

        Link: https://keygen.sh/changelog/

        ---

        Let me know if you have any questions, have feedback for me on things we can do better, or just things you'd like us to build.

        I appreciate every single one of you, and I'm honored that you trust Keygen. As always, I'll be here (and now in Slack!)

        Here's to another 9 years. *cheers*

        --
        Zeke, Founder <https://keygen.sh>

        p.s. don't forget about the Slack Connect invite! reply to this email to get one.
      TXT
    )
  end

  private

  def secret_key = ENV.fetch('STDOUT_SECRET_KEY')
  def encrypt(plaintext)
    crypt = ActiveSupport::MessageEncryptor.new(secret_key, serializer: JSON)
    enc   = crypt.encrypt_and_sign(plaintext)
                 .split('--')
                 .map { |s| Base64.urlsafe_encode64(Base64.strict_decode64(s), padding: false) }
                 .join('.')

    enc
  rescue => e
    Keygen.logger.error "[stdout.encrypt] Encrypt failed: err=#{e.message}"

    nil
  end
end
