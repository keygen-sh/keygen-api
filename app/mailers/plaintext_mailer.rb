# frozen_string_literal: true

class PlaintextMailer < ApplicationMailer
  default from: "Zeke Gabrielse <zeke@keygen.sh>"

  def low_activity_lifeline(account:)
    admin = account.admins.first

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Are you stuck?",
      body: <<~TXT
        I noticed that you created a Keygen account but there hasn't been much API activity on it lately. Is there anything I can do to help get things kickstarted?

        Just want to make sure you aren't stuck on anything. As a technical founder, it's easy for me to overlook roadblocks for new users. :)

        --
        Zeke, Founder <https://keygen.sh>
      TXT
    )
  end

  def trial_ending_soon_without_payment_method(account:)
    admin = account.admins.first

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Quick heads up",
      body: <<~TXT
        Just wanted to let you know that your free trial ends in 2 days. I also noticed that you don't have a payment method added yet. Is there anything I can do to help get one added?

        Hopefully you're getting some value out of Keygen and aren't stuck on anything? You can reply to this email directly with any feedback or questions.

        I'd be more than happy to extend your trial an extra 30 days if you're still in the dev phase -- just let me know.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. I know COVID has affected many businesses, so please let me know if there's anything I can do to help. :)
      TXT
    )
  end

  def trial_ending_soon_with_payment_method(account:)
    admin = account.admins.first

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Your trial is ending",
      body: <<~TXT
        I hope you've seen how Keygen can help your business save time and money with our software licensing API. Just wanted to give you a quick heads up that your free trial ends in 2 days.

        If Keygen has not met your expectations in anyway, we'd like to know about it. You can reply to this email directly with any feedback or questions.

        --
        Zeke, Founder <https://keygen.sh>
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
        I saw your first payment went through earlier and I just wanted to reach out real quick to thank you for your business.

        Keygen is a bootstrapped company and we love to connect with our customers. Is there anything we can do better?

        --
        Zeke, Founder <https://keygen.sh>
      TXT
    )
  end
end
