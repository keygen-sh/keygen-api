# frozen_string_literal: true

class PlaintextMailer < ApplicationMailer
  default from: "Zeke at Keygen <zeke@keygen.sh>"

  def low_activity_lifeline(account:)
    admin = account.admins.last

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
    admin = account.admins.last

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
      TXT
    )
  end

  def trial_ending_soon_with_payment_method(account:)
    admin = account.admins.last

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
    admin = account.admins.last
    call_to_actions = [
      %(If I could ask one question -- how did you hear about Keygen?),
      %(Do you have any feedback on how we can make Keygen better?),
      %(Is there anything we can do better?),
      %(What's one thing we could improve?),
      %(How did you hear about us?),
      %(Has Keygen helped you meet your licensing goals?),
    ]

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Keygen <> #{account.name}",
      body: <<~TXT
        I saw your first payment went through earlier and I just wanted to reach out real quick to thank you for your business. I'm glad to have you onboard.

        Keygen is a bootstrapped company and we love to connect with our customers. #{call_to_actions.sample}

        --
        Zeke, Founder <https://keygen.sh>
      TXT
    )
  end

  def prompt_for_testimonial(account:)
    admin = account.admins.last

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Keygen <> #{account.name}",
      body: <<~TXT
        Hope things are going well. I wanted to reach out and thank you again for your continued business. I'm glad Keygen has been able to provide value to your company, and hopefully we've made licensing your software a bit easier.

        Do you have a couple minutes today to give us a quick testimonial? As a thank you, we'll send you a $25 Amazon gift card (or a $50 account credit).

        You can leave a testimonial here: https://keygen.sh/record-a-testimonial/ (you can do video or text, and it can be a personal testimonial or on behalf of the company.)

        We're a bootstrapped company, and these testimonials help us out a lot. You can reply to this email directly with any feedback!

        Thanks again!

        --
        Zeke, Founder <https://keygen.sh>

        p.s. We also have a pretty cool affiliate program: https://keygen.sh/affiliates/ :)
      TXT
    )
  end

  def prompt_for_review(account:)
    admin = account.admins.last

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Keygen <> #{account.name}",
      body: <<~TXT
        Hope things are going well. I wanted to reach out and thank you again for your continued business. I'm glad Keygen has been able to provide value to your company, and hopefully we've made licensing your software a bit easier.

        Do you have a few minutes today to give us a quick review on Capterra so more companies can find us? As a thank you, all verified reviews will receive a $25 Amazon gift card (or a $50 account credit).

        You can leave a review here: https://keygen.sh/write-a-review/ (it can be a personal review or on behalf of the company.)

        If that's too much to ask, a short tweet tagging @keygen_sh would also be awesome! We'll give it a retweet.

        We're a bootstrapped company, and this would help us out a lot. You can reply to this email directly with any feedback!

        Thanks again!

        --
        Zeke, Founder <https://keygen.sh>

        p.s. We also have a pretty cool affiliate program: https://keygen.sh/affiliates/ :)
      TXT
    )
  end

  def prompt_for_first_impression(account:)
    admin = account.admins.last

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "What is your first impression?",
      body: <<~TXT
        I know you're still early in your licensing journey, but I'd love to hear your first impression while your thoughts are fresh.

        What do you think the most valuable features are so far? Is there anything missing?

        Also, please let me know if there's anything you're looking for but can’t find or if you're experiencing any technical issues.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. You can bookmark this link to quickly log into your account: https://app.keygen.sh/login?account=#{account.slug}
      TXT
    )
  end
end
