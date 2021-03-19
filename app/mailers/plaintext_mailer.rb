# frozen_string_literal: true

class PlaintextMailer < ApplicationMailer
  default from: "Zeke Gabrielse <zeke@keygen.sh>"

  def low_activity_lifeline(account:)
    admin = account.admins.first

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Have a quick question for you",
      body: <<~TXT
        Hey team,

        I noticed that you created a Keygen account but there hasn't been much API activity on it lately. Is there anything I can do to help get things kickstarted?

        Just want to make sure you aren't stuck on anything. As a technical founder, it's easy for me to overlook roadblocks for new users. :)

        --
        Zeke, Founder <https://keygen.sh>
      TXT
    )
  end

  def trial_ending_soon(account:)
    admin = account.admins.first

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Quick heads up",
      body: <<~TXT
        Hey team,

        I noticed that your trial is ending soon but there's no payment method added yet. Is there anything I can do to help get one added? I'd also be happy to extend your trial -- just let me know.

        Hopefully you're getting some value out of Keygen and aren't stuck on anything?

        --
        Zeke, Founder <https://keygen.sh>

        p.s. I know COVID has affected many businesses, so please let me know if there's anything I can do to help. :)
      TXT
    )
  end

  def first_payment_succeeded(account:)
    admin = account.admins.first

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Keygen <> #{account.name}",
      body: <<~TXT
        Hey team,

        I saw your first payment went through earlier and I just wanted to reach out real quick to thank you for your business.

        Keygen is a bootstrapped company and we love to connect with our customers. Is there anything we can do better?

        --
        Zeke, Founder <https://keygen.sh>
      TXT
    )
  end
end
