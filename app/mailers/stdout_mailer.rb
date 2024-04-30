# frozen_string_literal: true

class StdoutMailer < ApplicationMailer
  default from: 'Zeke at Keygen <zeke@keygen.sh>'

  def issue_zero(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: 'November in review -- trying something different',
      body: <<~TXT
        #{greeting} -- long time no update! Zeke here, founder of Keygen.

        (You're receiving this email because you or your team signed up for a Keygen account. If you don't
        find this email useful, you can unsubscribe below.)

        I'm gonna be trying something new -- a periodic email update covering "what's new" in Keygen. It
        was recently brought to my attention that I don't do a good job of surfacing new updates to Keygen
        customers, so I hope this changes that. If you don't want to receive emails like this, you can
        opt-out anytime by following this link:

          #{unsub_link}

        --

        A lot has happened in 2021, so this zeroth issue of "Stdout" (what I'll be calling this) may be
        a little bit lengthier than future issues. There are a lot of other, smaller, changes that have
        happened, but for those you can check out Keygen's changelog.

        To kick things off, let's talk software distribution --

        ## Keygen Dist v2

        A few months back, we rolled out a brand new version of our distribution API. We made the decision
        to build a better version from the ground up -- one that is fully integrated into our flagship
        software licensing API. This has been a huge goal of mine, really, since I first wrote the Go
        prototype for the first distribution API.

        Some of the rad features for Dist v2:

          - You can add entitlement constraints to releases, ensuring that only users that possess a license
            with those entitlements can access the release. E.g. a popular use case is locking a license to
            a specific major version of a product until they purchase an upgrade. This can be accomplished
            using entitlement constraints, with a V1 and V2 entitlement, respectively.

          - You can set a product's "distribution strategy", allowing you to either distribute your product
            releases OPENly to anybody, no license required, or only to LICENSED users (the default). This
            really opens up doors for Keygen to support a wider variety of business models, such as freemium
            distribution as well as open source (like our CLI, which I'll touch on in a sec).

          - Since the new distribution API is fully integrated into our licensing API, scoping releases
            per-license and per-user is now possible. When authenticated as a licensee, they only see
            the product releases they have a license for.

        We've deprecated our older distribution API, dist.keygen.sh. It'll continue to be available, but we
        recommend using our new API for all new product development.

        The new API is now available at api.keygen.sh.

        Docs: https://keygen.sh/docs/api/releases/

        ## Go SDK

        With the launch of our new distribution API, I really wanted to start focusing on SDKs. We recently
        rolled out our first SDK, for Go. With it, you can add license validation, activation, and automatic
        upgrades to any Go application. It's super slick.

        We're currently working on other SDKs as well, for Node, Swift, and C#. Up next will be a macOS SDK,
        written in Swift. Let me know if you have any specific requests for an SDK!

        Source: https://github.com/keygen-sh/keygen-go
        Docs: https://keygen.sh/docs/api/auto-updates/#auto-updates-go

        Next up, let's talk command line --

        ## Keygen CLI

        We just recently rolled out the beta for our new Keygen CLI. You can use it to sign and publish new
        software releases to the new aforementioned distribution API. Keygen's CLI itself is published
        using the CLI, and it utilizes our Go SDK for automatic upgrades, all backed by Keygen's new
        distribution API (it's dogfooding all the way down!)

        The Keygen CLI is easy to integrate into your normal build and release workflow, complete with support
        for CI/CD environments. Securely sign releases using an Ed25519 private key, and verify upgrades
        using a public key. You can generate a key pair with the CLI's genkey command.

        To install the CLI and try it out, run this "quick install" script:

            curl -sSL https://get.keygen.sh/keygen/cli/install.sh | sh

        The install script will auto-detect your platform and install the appropriate binary. You can, of
        course, install manually by visiting the docs, linked below.

        Source: https://github.com/keygen-sh/keygen-cli
        Docs: https://keygen.sh/docs/cli/

        ## Electron Builder

        We've teamed up with the electron-builder maintainers to craft a super slick integration, allowing
        you to easily provide automatic upgrades, served by the new distribution API, with only a few lines
        of code. (Publishing releases is just as easy -- electron-builder does all the work.)

            const { autoUpdater } = require('electron-updater')

            // Pass in an API token that belongs to the licensee (i.e. a user or
            // activation token)
            autoUpdater.addAuthHeader(`Bearer ${token}`)

            // Check for updates
            autoUpdater.checkForUpdatesAndNotify()

        I'm super stoked about this one. It's something I've been wanting to do since I first created Keygen,
        at a time where licensing APIs weren't even a thing. I hope this makes licensing and distributing
        an Electron app just a little bit easier!

        Source: https://github.com/electron-userland/electron-builder
        Docs: https://keygen.sh/docs/api/auto-updates/#auto-updates-electron

        --

        Well, that's it for this first issue of Stdout. Let me know if you have any feedback for me. We're
        going to make 2022 a great year -- complete with a brand new, much needed, UI overhaul (including
        a highly-requested *customer-facing* portal!)

        Thank you so much for your support!

        Until next time.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. If you know anyone, we have a new affiliate program: https://keygen.sh/affiliates/ :)
      TXT
    )
  end

  def issue_one(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: "What's new in Keygen: license key authentication!",
      body: <<~TXT
        #{greeting} -- Zeke here with another quick update.

        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        We heard you loud and clear! Activation tokens were not the most convenient authentication mechanism in the world. They had to be created after a license was created, which required multiple API requests, and figuring out which values to send to an end-user was kind of a headache. Should you send the license key? The activation token? Both? (Typically, the answer was both -- which kind of sucked.)

        Starting today, you can configure your policies to have a license key authentication strategy. Doing so will allow you to authenticate with our API using a license key. Simply adjust your policy's authentication strategy to LICENSE, and start passing a license key into any API request's Authorization header using a new License scheme:

          Authorization: License C1B6DE-39A6E3-DE1529-8559A0-4AF593-V3

        It's that simple! No activation token required!

        Instead of figuring out which values to send to your end-users during fulfillment — all you have to do is send them a license key. No other values required! You can then perform any API request that you could do with an activation token, like activate a machine, download a release upgrade, or send a heartbeat ping.

        You can, of course, continue to use activation tokens! Nothing has changed there. And pretty soon, you'll be able to adjust permissions on a per-token basis. So activation tokens will still have a place — where more fine-grained access control is needed. But for the majority of use cases, switching to license key authentication will likely simplify your integration and fulfillment, as well as your software's end-user experience, which we think is a win-win.

        Note on backwards compatibility: for existing policies, and any new policies — nothing has changed. This is an opt-in feature only. Policies will default to using a TOKEN authentication strategy, which behaves exactly like it did before we introduced this new authentication scheme.

        If you'd like to opt-in, switch your policy's authentication strategy to LICENSE. (You can even accept both types of authentication, using MIXED, which should help during migration.)

        --

        Aside: we're looking for users for our new Zapier integration! Zapier needs us to have a handful of live users before we're able to publish our integration publicly. To try it out, use the invite link at the bottom of this page:

          https://keygen.sh/integrate/zapier/

        --

        Well, that's it for the second issue of Stdout (well, first... if we count from zero). Let me know if you have any feedback for me -- would love to hear it.

        There's a lot more cool stuff coming up that I'm excited to share.

        Until next time.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. for more on API authentication, check out our updated docs: https://keygen.sh/docs/api/authentication/
      TXT
    )
  end

  def issue_two(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: "What's happened in 2022 so far",
      body: <<~TXT
        #{greeting} -- Zeke here with yet another update! (I figured I'd sneek into your inbox before it's flooded with jokes on April 1st.)

        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        Lots has happened this year! It's actually shaping up to be one of our most productive years yet, and we're just getting started.

        So what's new in Keygen? Let's dig in and find out.

        ## License files

        Since 2016, our process for licensing offline devices has evolved quite a few times. First, we didn't do much for offline licensing. (Very much to our customer's dismay.)

        Then, we added the ability to sign and encrypt license keys. This was a hit! Now customers were able to transfer data to offline devices and cryptographically verify the integrity of their license keys.

        Then, we added the ability to generate activation "proofs." These allowed a customer to cryptographically sign a proof of activation for a device, typically activated elsewhere on behalf of the offline device.

        But although those have worked great, the embedded datasets are immutable. We wanted something easier, something more standardized, and something that was able to provide the same up-to-date datasets that our API can provide, but to offline and air-gapped environments.

        Enter, license files --

        Starting today, you can "check-out" a license or machine resource, using their check-out action, and in return, we'll send you a cryptographically signed "certificate" that looks something like this:

          -----BEGIN LICENSE FILE-----
          eyJlbmMiOiJsSTc4N0QwcGZua1RvRDVOSjFpRXlaU093Q09QQ0NOdktKZHpC
          MlpSYlZBQzVsQUhjdzJSUi8xTEhrcXc0ZG5rUEl3TFVYRzhmUzk1R0JWTmtz
          d2JDTmllWm1uOElHeGpkbUY2T1RmNjRzOHlpbFRpL3FlUzJSTlhBdGJBWjUw
          ...
          QWtpVnBudmFWTFhVdkY1UGJJYjNFRXA0YlZNOU1xWjBhNjhQa1R1MW5VS0E0
          TlJWWGp6Ym5DRkF6V3lOU3NUeG9xZm9MV2FlWlhITEZnR21Ub2VBdz09Iiwi
          YWxnIjoiYWVzLTI1Ni1nY20rZWQyNTUxOSJ9
          -----END LICENSE FILE-----

        License file certificates can be decoded (and decrypted), giving you an up-to-date "snapshot" of a machine, a license, and even their entitlement data. They have a digitally signed expiration so you can know exactly when your customer's next check-out should be.

        License file certificates can be saved with a `.lic` file extension and can be distributed to offline or air-gapped devices using email, USB flash drive, license dongle, or any other means (like QR codes!)

        License files work great alongside signed license keys. And we believe they're a great replacement for machine proofs, so please check them out if you're utilizing proofs.

        Check out the docs: https://keygen.sh/docs/api/licenses/#licenses-actions-check-out

        ## Zapier

        Our Zapier integration has officially moved out of beta! Thanks for all the feedback over the last couple months. We're super stoked to partner with Zapier here, and we're already seeing some really cool and creative ways of using Keygen with Zapier.

        If you're looking for a no-code solution for integrating Keygen with other third-party services, such as ChargeBee or Stripe, or even SalesForce, maybe give Zapier a peek.

        More info here: https://keygen.sh/integrate/zapier/

        ## Custom domains

        A few months ago we "officially" rolled out custom domains. It had been available for awhile, but we just didn't really advertise it much outside of our Ent tiers unless customers asked. Now available to purchase for all tiers, custom domains let you set up Keygen behind your own domain name using a CNAME DNS record. The add-on is super easy to set up, and allows your team to completely whitelabel our API behind your own domain.

        If you want to get set up with a custom domain, reply back and we can chat. Pricing starts at $995/yr/domain.

        More info here: https://keygen.sh/docs/custom-domains/

        ## Groups (about time!)

        It's been a *long* time coming, but it's finally here -- Groups!

        User, license and machine resources can be added into Groups, allowing you to natively set up a "team" or company structure to more easily offer licensing options to larger groups. In addition, groups can have limits on the number of each resource allowed in the group.

        For example, you could create a group that allows up to 5 users, 5 licenses and 10 total machines. These group rules would be enforced collectively for all licenses in addition to each license's individual ruleset.

        In the future, we'll be expanding upon the Group resource to add Owners, paving the way for self-management options of Groups.

        Docs: https://keygen.sh/docs/api/groups/

        ## Dead or alive?

        We've added quite a few nifty features to our machine heartbeat system. You can now configure how dead machines are culled, whether or not dead machines can be resurrected, and finally, we added the ability to enforce heartbeats monitors on all licenses.

        These changes add a lot of additional depth to our heartbeat system, overall making the system a lot more flexible, especially when licensing virtual and cloud environments.

        We can't wait to see what people build with these.

        ## User-locked licensing

        We've made a few small but significant changes to our User model that should make implementing a user-locked licensing model much more straightforward.

        1. We removed the requirement for a user to have a password. Now, a user simply needs an email address. (We call these passwordless users.)

        2. We added the ability to scope license validations to a specific user, by email address.

        3. We added the ability to ban a user -- very similar to suspending a license.

        All of these combined make the typical user-locked licensing flow of prompting for an email address and license key super easy -- you send both of those values to our API during a license validation request, and we assert that the license is valid and owned by a user with that email.

        We're hoping this really smooths out our offering for user-locked licensing.

        Docs: https://keygen.sh/docs/choosing-a-licensing-model/user-locked-licenses/

        ## Template variables

        Last but not least --

        We've added support for template variables in signed license keys. Previously, creating a signed license key that contained the license's "expiry" required you to manually calculate the expiry, and then set it in the license's signed dataset, in addition to the license's expiry attribute during creation. Well, we heard your cries and we've simplified things. Moving forward, you can use the `{{expiry}}` template variable for this. It's precalculated by us, and guaranteed to match the license's value at time of creation.

        There are other variables as well, for example `{{id}}` and `{{created}}`. As needs arise, we'll continue to expand upon the available template variables for signed keys.

        We hope this simplifies crafting signed key datasets.

        Docs: https://keygen.sh/docs/api/cryptography/#cryptographic-keys-template-vars

        --

        That's it for the third installment of Stdout. We're looking forward to what's coming up. Let me know if you have any feedback for me -- would love to hear it.

        (And yes -- the new UI is coming! Soon. Lots of behind-the-scenes API work has been happening, like all of the above, to accommodate the new UI's features.)

        Until next time.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. all of these changes and more are covered in our changelog: https://keygen.sh/changelog/
      TXT
    )
  end

  def issue_three(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: 'Our servers caught fire!',
      body: <<~TXT
        Only kidding! -- but this summer has been a hot one! Luckily, our servers weren't in Texas. (Unluckily, I am... and it's *still* hitting the 90s here.)

        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        Zeke here with another quick Keygen update. The last couple months has been chock full of behind-the-scenes work, but some of that work is starting to surface through new features.

        To kick things off, let's cover some of the new features for our enterprise Ent tiers.

        ## Permissions

        Historically, Keygen has implemented a role-based strategy with fixed permissions for authorization, and it has worked quite well. But many enterprises have been asking for more fine-grained control around permissions. For example, they may want to create an admin that can only manage a subset of resources, or a read only user, or they want to create a license that can only validate and activate itself -- nothing more.

        Until now, this wasn't possible. But we after months of hard work, we've finally rolled out a powerful permission system that makes all of this, and more, possible.

        The new permission system is only available on our Ent tiers. Standard tiers will continue to function as they always have.

        Please head on over to the blog and the docs to dig in further:

        Blog: https://keygen.sh/blog/announcing-advanced-roles-and-permissions/

        Docs: https://keygen.sh/docs/api/authorization/

        ## Static IPs

        Historically, we've been unable to support static IPs due to a limitation of one of our infrastructure providers. But we know that whitelisting a domain name can be a hard sell for some customers, or it may even be *impossible* depending on the way a customer's private network is configured, complicating an integration.

        To make our offering even better and allow it to be used in even more environments, we've started rolling out static IP addresses for those on the Ent tier. Huge thanks to https://www.quotaguard.com/ for helping us out here.

        If you're interested, please let us know and we'll get you set up. This feature is only available on our Ent tiers.

        Docs: https://keygen.sh/docs/static-ips/

        --

        Next, we'll cover new features and the like that are available on all Std and Ent tiers --

        ## Processes

        As our product grows, we continue to encounter new and novel ways in which our customers utilize our API to their license software products. Sometimes our API supports these novel scenarios, but other times it doesnt, and we take notes and start brainstorming a solution.

        One area in which our API lacked was managing application instances on a per-machine basis. Essentially, we want to be able to limit the number of machines per-license, as well as the number of instances per-machine.

        Our API supported the former and has since day 1 -- limiting the number of machines per-license -- but not the number of instances per-machine.

        Well, we finally have an answer to the latter problem: Processes.

        Processes allow you to limit the number of PIDs per-machine, very similarly to how a machine limits the number of devices per-license.

        We hope this is yet another step towards making our API the #1 choice for licensing software.

        Docs: https://keygen.sh/docs/api/processes/

        ## API Versioning

        If you're one of those that peek our changelog from time to time, you may have noticed that we've made some breaking changes recently.

        But if you don't peek our changelog, you may not have noticed these breaking changes at all.

        Wait... what?

        You heard that right! We've made some rather large breaking changes to our API and you probably didn't even notice (and it'd be a major bug if you did!)

        That may seem like a stark contradiction, but we've spent a considerable amount of time recently on our API versioning strategy. We even wrote a blog post about it, and open sourced how we do it!

        Please check out the post (and gem) if you're interested in API versioning. And peek our changelog if you're curious about the recent changes.

        Blog: https://keygen.sh/blog/breaking-things-without-breaking-things/

        Gem: https://github.com/keygen-sh/request_migrations

        Docs: https://keygen.sh/docs/api/versioning/

        Changelog: https://keygen.sh/changelog/

        ## New SDK

        Our Go SDK has a new major version available. This release coincides with the breaking changes mentioned above. Be sure to check it out if you're a Gopher.

        In related news -- we're currently working on a Rust SDK. We're hoping to have a slick integration with Tauri as well.

        Please let us know what languages you're hoping for next!

        Source: https://github.com/keygen-sh/keygen-go

        ## New CLI

        Our CLI also has a new major version available. The CLI has been completely reworked to coincide with the changes made to our distribution API.

        We think it's in a much better place now, offering an improved DX for publishing software artifacts.

        Source: https://github.com/keygen-sh/keygen-cli

        Action: https://github.com/unhack/keygen-action

        Docs: https://keygen.sh/docs/cli/

        --

        That's all for now. I appreciate your continued support. Lots in store for the future, including a rather big surprise that ryhmes with "ocean horse."

        Until next time.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. we're hiring: https://keygen.sh/jobs/
      TXT
    )
  end

  def issue_four(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: 'Keygen goes open source!',
      body: <<~TXT
        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        Zeke here with a pretty big update -- Keygen is now open source!

        As some of you may already know, this has been in the works for nearly a year. I'm incredibly excited for this change, and I hope you will be too.

        So, what does this mean for you and for Keygen?

        ## What's changing

        If you're a current Keygen Cloud customer (what we're calling our SaaS moving forward), nothing changes. Starting today, in addition to Keygen Cloud, Keygen is now available in two self-hosted editions: Keygen CE and Keygen EE.

        Each edition offers unique features and benefits, and you can choose the edition that best suits your specific needs:

        - Keygen CE: the Community Edition (CE) of Keygen. This is a self-hosted single-tenant version of Keygen's API. To start using Keygen CE, you can visit our GitHub or follow our self-hosting instructions. Keygen CE is free (as in beer) to self-host.

        - Keygen EE: the Enterprise Edition (EE) of Keygen. Also a self-hosted version of Keygen's API, Keygen EE can be single- or multi-tenant depending on configuration and license. Keygen EE comes with features that are more enterprise-centric such as environments, request logs, event (audit) logs, and advanced permissions. Keygen EE will require a valid license key to self-host.

        - Keygen Cloud: the SaaS version of Keygen. Keygen Cloud is a fully-managed cloud service that provides all the benefits of Keygen EE without the need to manage infrastructure. This is the Keygen you already know and love.

        ## Why open source?

        Well, a lot of reasons. So many that I wrote a blog post about the why:

          https://keygen.sh/blog/all-your-licensing-are-belong-to-you/

        Please give it a read. Links to code and docs are there too.

        ## What next?

        If you're interested in Keygen EE, reply to this email directly or reach out to sales@keygen.sh anytime to start a conversation.

        For self-hosting Keygen, check out the new self-hosting docs:

          https://keygen.sh/docs/self-hosting/

        Star us on GitHub:

          https://github.com/keygen-sh/keygen-api

        Have questions or comments? I'm all ears. You can reply back to this email directly.

        Until next time.

        --
        Zeke, Founder <https://keygen.sh>
      TXT
    )
  end

  def issue_five(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: 'Environments and packages and engines, oh my!',
      body: <<~TXT
        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        This has been a big couple months, with July being our biggest month yet. Since going open source, we've seen a ton of new faces ... err, read a ton of new texts ... err, okay -- you know what I mean. Lots of new people using Keygen to license their applications, big and small.

        It's been crazy to see so many people interested in self-hosting Keygen, both CE and EE. The first sale for Keygen EE was exilterating, moving from being a SaaS business into multi-prem. That feeling brought me back to my first sale of Keygen, 7 years ago.

        If you're interested in exploring self-hosting Keygen EE for your organization, reply back to this email and I can get you set up with a 30-day trial. No strings attached.

        But with that said, some big features were released over the last couple months.

        ## Environments

        It only took 7 years, but environments are now available. You can use the new environment resource to segregate data within your Keygen account.

        Most companies will utilize this for an isolated "sandbox" environment, but the system is flexible enough for other applications as well.

        For example, you can create a "shared" environment for QA, where read-only production data augments the environment-specific resources. It's a powerful system, and like always, we're excited to see what people build with it.

        Currently, environments are available via the API only. We'll be adding them to the new Portal app in the works (more on that soon).

        Docs: https://keygen.sh/docs/api/environments/

        ## Packages

        Another huge feature is release packages. Historically, releases were managed one-application-per-product. But this rather was inflexible, because it meant that licenses couldn't be shared across multiple applications, even if some of the applications were plugins or add-ons for the same product. This meant that those plugins would either require a separate license, or they wouldn't be able to be versioned like a normal release.

        But packages allow you to separately manage releases for multiple applications under a single product umbrella.

        This could mean a flagship product with various add-ons, all licensed together, but versioned and distributed separately.

        Or it could mean offering a series of "packages" across various languages, e.g. npm, Rubygems, PyPI, etc.

        Docs: https://keygen.sh/docs/api/packages/

        ## Engines

        Which brings us into our next bit...

        As part of our packages launch, we're introducing release engines. These will offer compatibility with popular package managers, such as npm and PyPI.

        With the introduction of engines, we've added support for our first package manager: PyPI.

        You can now upload private PyPI packages and let licensed users install the packages using pip:

          pip install example --index-url https://license:<key>@pypi.pkg.keygen.sh/demo/simple

        We'll be adding others, such as npm, Electron, Tauri, and OCI very soon.

        Docs: https://keygen.sh/docs/api/engines/

        ## Second factors

        Last but not least, we've made our second factor API endpoints public (i.e. we documented them). This means that you can now offer TOTP second factors (a.k.a. 2FA/MFA) to the users of your applications. Think: Authy, Google Authenticator, etc.

        We've been using these endpoints for our own dashboard for years to offer MFA to our users (i.e. you), and we figured documenting the API for others to use would increase security for all.

        Let us know what you think. We'll be interating on this over the next few weeks.

        Docs: https://keygen.sh/docs/api/users/#second-factors

        ## Community

        Our Discord community is growing, so if you have questions or just want to talk licensing or business, drop in and say hi.

        Link: https://discord.gg/TRrhSaWSsN

        --

        That's it for now. Lots of new stuff coming up, including more information on the soon-to-be-open-source Portal.

        Have questions or comments? I'm all ears. You can reply back to this email directly.

        Until next time.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. we're creeping up on 300 stars on GitHub, so if you haven't already, give us a star. :)

        Link: https://github.com/keygen-sh/keygen-api
      TXT
    )
  end

  def issue_six(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: "The straw that took Keygen down for over 10 hours",
      body: <<~TXT
        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        On February 5th, I woke up at 4am to my phone lighting up with a barrage of notifications. Through my daze, I scanned text messages and calls from numbers I didn't know, Discord chats from the community, and thousands of emails all saying the same thing: Keygen is DOWN. And it had been down... for over 4 hours. Total downtime on Februrary 5th was 5 and a half hours. And I wish I could say that was the end of the nightmare, but unfortunately, it wasn't.

        Within the next 24 hours, we would go down again for another 5 hours. Why this occurred was a mixture of things, from failures in Keygen's on-call alerting, to failures to adequately scale to meet a sudden increase in traffic, to failures in a third-party dependency. But the onus is on me.

        To my customers: I am deeply sorry. I regret that this happened. I understand the importance that business-critical software like Keygen has on day-to-day operations, and I am sorry if this outage caused you or your business any negative effects.

        I know many are wondering exactly what happened. And in case you or your stakeholders are curious, I've written a detailed postmortem here:

          https://keygen.sh/blog/that-one-time-keygen-went-down-for-5-hours-twice/

        Have questions or comments? I'm here. You can reply back to this email directly.

        --
        Zeke, Founder <https://keygen.sh>
      TXT
    )
  end

  def issue_seven(subscriber:)
    return if
      subscriber.stdout_unsubscribed_at?

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
      subject: "What's new in Keygen: multi-user licenses",
      body: <<~TXT
        (You're receiving this email because you or your team signed up for a Keygen account. If you don't find this email useful, you can unsubscribe below.)

          #{unsub_link}

        --

        If I cataloged and ranked all of Keygen's feature requests over the last 8 years by popularity, multi-user licenses would be at the forefront. It's been Keygen's most requested feature by a landslide. But trying to figure out how to implement it in a backwards compatible way always kept the project on the backburner. It was a very hard project.

        That's why, I'm super excited to announce that multi-user licenses is now generally available. This is the culmination of nearly 6 months of hard work, and overcoming lots and lots of technical challenges. (If I'm being honest, the technical challenges this project has had cannot be understated. Multiple soon-to-be open source libraries were born out of the project -- but I'll leave that topic for another day.)

        So, what exactly *is* multi-user licenses anyway?

        As the name may suggest, we are changing the relationship between licenses and users from a *has-one* to a *has-many* relationship. In non-engineering terms -- previously, a license could be associated to only a single user, and now not only can a license be associated to a user (now referred to as its owner), but it can also have multiple *other* users associated to it.

        Going from a single-user model to a multi-user model is quite a big shift, and a lot of internal code has changed to reflect this shift, but all of it has been done in a way that is 100% backwards compatible. So that means nothing changes i.r.t. existing integrations. If you're technical, you know how such a seemingly small change can be a significant challenge, and maintaining 100% backwards compatibility even more so. But we're stoked to share that we were able to pull it off.

        Mutli-user licenses opens up new possibilities for a lot of licensing models that have historically been hard, or even impossible, to implement in Keygen, such as true per-user licensing, and other variations of per-seat licensing. We've seen a big trend towards per-user licensing models, and we wanted Keygen to be able to provide the building blocks for this increasingly popular choice.

        Historically, you *could* work around these shortcomings by retro-fitting machines to model users, or by issuing multiple licenses (e.g. a license per-user), but there were always major tradeoffs, and it ultimately felt like a hack (because it *was*).

        Starting today, it's as simple as creating a license, and then attaching 𝑛 users to that license.

        If you're interested in reading more, check out this short blog post:

          https://keygen.sh/blog/announcing-multi-user-licenses/

        I'd like to reiterate: if you have an existing Keygen integration, *nothing changes.* We strive to maintain 100% backwards compatibility, and we've put a considerable amount of effort into our API versioning system to ensure we meet that promise.

        Right now, this is an API-only feature. We'll be adding the new functionality to the Dashboard soon.

        Anyways, check it out, build with it, and let me know what you think.

        Until next time.

        --
        Zeke, Founder <https://keygen.sh>

        p.s. for all you self-hosters, we'll cut a new Keygen CE and EE release soon (after it's been battle-tested in Keygen Cloud).

        p.p.s. we broke 500 stars on GitHub! Star us if you haven't yet: https://github.com/keygen-sh/keygen-api
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
