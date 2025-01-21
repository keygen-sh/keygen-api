# frozen_string_literal: true

class PlaintextMailer < ApplicationMailer
  default from: "Zeke Gabrielse <zeke@keygen.sh>"

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
    return if
      account.free?

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
    return if
      account.free?

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
    return if
      account.ent?

    admin = account.admins.last
    call_to_actions = [
      %(If I could ask one question -- how did you hear about Keygen?),
      %(Do you have any feedback on how we can make Keygen better?),
      %(Is there anything we can do better?),
      %(What's one thing we could improve?),
      %(How did you hear about us?),
      %(Where did you find us?),
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
    return if
      account.ent?

    admin = account.admins.last

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Keygen <> #{account.name}",
      body: <<~TXT
        Hope things are going well. I wanted to reach out and thank you again for your continued business. I'm glad Keygen has been able to provide value to your company, and hopefully we've made licensing your software a bit easier.

        Do you have a couple minutes today to give us a quick testimonial? As a thank you, I'll send you a $20 gift card to your favorite coffee shop or lunch spot!

        You can leave a short testimonial here: https://keygen.sh/record-a-testimonial/ (you can do video or text, and it can be a personal testimonial or on behalf of the company.)

        We're a bootstrapped company, and these testimonials help us out a lot. You can reply to this email directly with any feedback!

        Thanks again!

        --
        Zeke, Founder <https://keygen.sh>

        p.s. We also have a pretty cool affiliate program: https://keygen.sh/affiliates/ :)
      TXT
    )
  end

  def prompt_for_review(account:)
    return if
      account.ent?

    admin = account.admins.last

    mail(
      content_type: "text/plain",
      to: admin.email,
      subject: "Keygen <> #{account.name}",
      body: <<~TXT
        Hope things are going well. I wanted to reach out and thank you again for your continued business. I'm glad Keygen has been able to provide value to your company, and hopefully we've made licensing your software a bit easier.

        Do you have a few minutes today to give us a quick review so more companies can find us? As a thank you, I'll send you a $20 gift card to your favorite coffee shop or lunch spot!

        You can leave a short review here: https://keygen.sh/write-a-review/ (it can be a personal review or on behalf of the company.)

        If that's too much to ask (totally understand), a short tweet tagging @keygen_sh would also be awesome! We'll give it a retweet.

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
      subject: "What are you working on?",
      body: <<~TXT
        Hope things are well. I know you're still early in your licensing journey, but I'd love to hear more about what you're working on?

        Also, please let me know if there's anything you're looking for but can't find or if you're experiencing any technical issues.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. You can bookmark this link to quickly log into your account: https://app.keygen.sh/login?account=#{account.slug}
      TXT
    )
  end

  def price_increase_notice(account:)
    return if
      account.ent?

    account.admins.each do |admin|
      mail(
        content_type: "text/plain",
        to: admin.email,
        subject: "Attention: price increase starting May 1st, 2022",
        body: <<~TXT
          Hey team,

          (You're receiving this email because you're an admin of Keygen account `#{account.slug}`.)

          Honestly, this is an email that I really hate writing. And I want to start off with some thanks -- thanks to all of our current and past customers, for supporting Keygen over the years, and for being such great people. Keygen has been growing non-stop and I can't wait to see what the future brings. We have some awesome stuff in store for 2022!

          But due to increased operating costs, we're going to be increasing prices across the board on May 1st, 2022. In our nearly 7 years in business, we've never raised prices for our customers -- we've *always* grandfathered in existing customers when making any pricing changes. But with these increased operating costs and the additional value we've added to the service over the years, we feel that a price increase is necessary.

          If you'd like to lock yourself into your current pricing for the next year, please upgrade to a yearly plan before May 1st, 2022. If you're already on a yearly plan, these changes will come into effect upon renewal.

          Below are the new prices, going into effect on May 1st, 2022. Your account will automatically be upgraded, unless canceled (and we'd hate that -- so please reach out if that's the case.)

          - Tier 0: $19 to $29/mo ($290/yr, discontinued)
          - Tier 1: $39 to $49/mo ($490/yr)
          - Tier 2: $59 to $79/mo ($790/yr)
          - Tier 3: $99 to $129/mo ($1,290/yr)
          - Tier 4: $159 to $199/mo ($1,990/yr)
          - Tier 5: $319 to $399/mo ($3,990/yr)
          - Tier 6: $639 to $799/mo ($7,990/yr)
          - Ent 1: $1,279 to $1,599 ($15,990/yr)
          - Ent 2: $2,559 to $3,199 ($31,990/yr)
          - Ent 3: $4,919 to $6,149 ($61,490/yr)

          If you're on an even older plan than these (thanks for sticking with us!), we ask that you upgrade to one of the new plans. If you're on the free tier, you will continue to stay on the free tier. You can choose a yearly plan before May 1st to be locked into our current pricing as of this email.

          You can upgrade your plan from your billing dashboard: https://app.keygen.sh/billing (if you don't see your desired yearly plan listed -- let me know and I'll get it squared away for you.)

          We don't make these changes lightly, and we hope that you understand. Please let me know if you have any questions or concerns.

          --
          Zeke, Founder <https://keygen.sh>

          p.s. We just launched Groups, so be sure to peek our changelog and check that out. I know it's been a highly-requested feature!
        TXT
      )
    end
  end

  def price_increase_reminder(account:)
    return if
      account.ent?

    account.admins.each do |admin|
      mail(
        content_type: "text/plain",
        to: admin.email,
        subject: "Re: price increase starting May 1st, 2022",
        body: <<~TXT
          Hey team,

          (You're receiving this email because you're an admin of Keygen account `#{account.slug}`.)

          Quick reminder that we'll be increasing our prices soon. Again, this is the first time we've ever increased prices for our customers, and we don't take this event lightly. We'll be increasing prices across the board due to increased operating costs.

          Below are the new prices, going into effect on May 1st, 2022 (less than 2 weeks). Your account will automatically be upgraded, unless you're on a free tier or you cancel (and we'd really hate that -- so please reach out).

          - Dev 0: no changes (i.e. it's still free)
          - Tier 0: $19 to $29/mo ($290/yr)
          - Tier 1: $39 to $49/mo ($490/yr)
          - Tier 2: $59 to $79/mo ($790/yr)
          - Tier 3: $99 to $129/mo ($1,290/yr)
          - Tier 4: $159 to $199/mo ($1,990/yr)
          - Tier 5: $319 to $399/mo ($3,990/yr)
          - More: https://keygen.sh/pricing/

          If you'd like to lock yourself into your current rate for the next 12 months, please upgrade to a yearly plan before May 1st, 2022. If you're already on a yearly plan, these changes will automatically come into effect upon renewal.

          Please reach out if you'd like me to switch you over to a yearly subscription at your current rate and I can get that handled for you.

          For low volume accounts, we also have a free tier called Dev 0 which you can downgrade to at anytime.

          Thanks again for your understanding and continued business. Let me know if you have any questions or concerns.

          --
          Zeke, Founder <https://keygen.sh>

          p.s. We just rolled out "processes", a great way to control application concurrency on machines. (More: https://keygen.sh/docs/api/processes/)
        TXT
      )
    end
  end
end
