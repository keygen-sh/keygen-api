[![Keygen CI](https://github.com/keygen-sh/keygen-api/actions/workflows/test.yml/badge.svg)](https://github.com/keygen-sh/keygen-api/actions)
[![Better Uptime Badge](https://betteruptime.com/status-badges/v1/monitor/95ne.svg)](https://betteruptime.com/?utm_source=status_badge)

# Keygen

Keygen is an open source software licensing and distribution API, built
for developers, by developers. Use Keygen to add license key validation,
entitlements, and device activation to your business's desktop apps,
server applications, on-premise software, and other products.

## Software licensing for everyone

Keygen comes in two editions. Keygen CE is our Community Edition, and is
free (as in beer) to self-hosted for personal and commercial use. Keygen
EE is our Enterprise Edition, and it requires a license key to use.
Keygen EE comes with enterprise-grade features like request logs,
audit logs, permissions environments, and more.

I built Keygen to make software licensing accessible to everyone.

## Managed hosting with Keygen Cloud

The easiest way to get started with Keygen is with [our official managed
service in the cloud][keygen-cloud]. We'll handle the hard stuff — high
availability, backups, security, and maintenance — while you focus on
product.

Our managed hosting can save a substantial amount of developer time and
resources. For most businesses, this ends up being the best value
option and the revenue goes to funding the maintenance and further
development of Keygen. So you’ll be supporting open source software
and getting a great service!

## Self hosting with Keygen CE

Keygen is a fully open source software licensing and distribution API, and
we have a free (as in beer) [self-hosted solution][self-hosting]. Keygen Community
Edition is exactly the same code base as our managed Cloud solution, but with
a less frequent release schedule (think of it as an LTS release).

Bug fixes and new features are released to the Cloud version several times
per week. Features are battle-tested in the Cloud which allows us to fix
any bugs before the general self-hosted release. Every 6 months, we
combine all the changes into a new self-hosted release.

Keygen CE does lack a few features from Keygen Cloud, which are available
in [Keygen EE][keygen-ee].

Interested in self-hosting Keygen? Take a look at our [self-hosting docs][self-hosting].

## Self hosting with Keygen EE

Keygen is also enterprise-grade, battle-tested in Keygen Cloud with some of
the best brands in the world. The following features are available in
Keygen Enterprise Edition:

- **Request logs**: keep a historical record of API requests, along with who
  made the request, the request body, response body, status code, IP address,
  and other information.
- **Event logs**: keep an audit trail of every single event that happens on a
  Keygen account.
- **Environments**: manage separate environments within a Keygen account, from
  test environments, to a sandbox, to QA, to production.
- **Permissions**: enterprise-grade roles and permissions.
- **SSO/SAML**: support for SSO/SAML coming soon.

Keygen uses Keygen EE in production to run Keygen Cloud, which is used to
license Keygen EE. It's ~~turtles~~ Keygens all the way down.

To obtain a license key, please [reach out][sales].

## Sustainability

Our only sources of funding for Keygen is our premium, managed service for
running Keygen in the Cloud, and Keygen EE. But if you're looking for an
alternative way to support the project, we've put together [some
sponsorship options][sponsor].

If you choose to self-host Keygen CE, you can [become a sponsor][sponsor],
which is a great way to give back to the community and to contribute
to the long-term sustainability of the project.

## Support

Keygen CE is a community supported project and there are no guarantees that
you will receive support from the creators of Keygen to troubleshoot your
self-hosting issues. There is [a community supported Discord][discord]
where you can ask for help.

If you do need support guantantees, consider becoming a [Keygen Cloud][keygen-cloud]
customer, or [purchasing Keygen EE][sales].

## Developing

### Setup

To install dependencies, run:

```bash
bundle
```

To initialize the database, run:

```bash
rails db:setup
```

To setup Keygen, run:

```bash
rake keygen:setup
```

### Running

To start the server, run:

```bash
bundle exec rails s
```

To start a worker, run:

```bash
bundle exec sidekiq
```

### Testing

To run the entire test suite, specs and features, run:

```bash
rake test
```

To run Cucumber features, run:

```bash
rake test:cucumber
```

To run Rspec specs, run:

```bash
rake test:rspec
```

## License

Keygen is licensed under the [Elastic License 2.0 (ELv2)](https://github.com/keygen-sh/keygen-api/blob/master/LICENSE.md) license because it provides the best balance between freedom and protection. The ELv2 license is a permissive license that allows you to use, modify, and distribute Keygen as long as you follow a few simple rules:

1. **You may not provide Keygen's API to others as a managed service.** For example, you _cannot_ host Keygen yourself and sell it as a cloud-based licensing service, competing with Keygen Cloud. However, you _can_ sell a product that directly exposes and utilizes Keygen's API, as long as Keygen cannot be used outside of your product for other purposes (such as your customer using an embedded Keygen EE instance to license _their_ product in addition to _your_ product).

1. **You may not circumvent the license key functionality or remove/obscure features protected by license keys.** For example, our code contains [license gates](https://github.com/keygen-sh/keygen-api/blob/ddbeed71543627fc15d37342c937e8bb4ef97157/app/models/environment.rb#L2) that unlock functionality for Keygen EE. You _cannot_ remove or change the licensing code to, for example, unlock a Keygen EE feature in Keygen CE.

1. You may not alter, remove, or obscure any licensing, copyright, or other notices.

Anything else is fair game. There's no clause that requires you to open source modifications.

You can self-host Keygen EE to license your enterprise application.

You can embed Keygen CE in your on-premise application.

You can run Keygen CE on a private network.

You can fork Keygen and go closed-source.

If the ELv2 license doesn't work for your company, please [reach out][sales].

## Is it any good?

Yes.

[keygen-cloud]: https://keygen.sh
[self-hosting]: https://keygen.sh/docs/self-hosting/
[sponsor]: https://github.com/sponsors/ezekg
[support]: mailto:support@keygen.sh
[discord]: https://discord.gg/yednR566
[contribute]: https://keygen.sh/contrib/
[license]: https://keygen.sh/license/
[sales]: mailto:sales@keygen.sh
