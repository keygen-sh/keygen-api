<a href="https://keygen.sh?ref=keygen-api">
  <div>
    <img src="https://keygen.sh/images/logo-pill.png" width="200" alt="Keygen">
  </div>
</a>
<br>

[![Keygen CI](https://github.com/keygen-sh/keygen-api/actions/workflows/test.yml/badge.svg)](https://github.com/keygen-sh/keygen-api/actions)
[![Discord Community](https://img.shields.io/badge/discord-community-blue)][discord]

# Keygen

Keygen is a fair source software licensing and distribution API, built
for developers, by developers. Use Keygen to add license key validation,
entitlements, and device activation to your business's desktop apps,
server applications, on-premise software, and other products.

## Software licensing for everyone

Keygen comes in two editions. Keygen CE is our Community Edition, and is
free (as in beer) to self-host for personal and commercial use. Keygen
EE is our Enterprise Edition, and it requires a license key to use.
Keygen EE comes with dedicated support, as well as enterprise-grade features
like request logs, audit logs, permissions, environments, and more.

I built Keygen to make software licensing accessible to everyone.

## Managed hosting with Keygen Cloud

The easiest way to get started with Keygen is with [our official managed
service in the cloud][keygen-cloud]. We'll handle the hard stuff — high
availability, backups, security, and maintenance — while you focus on
product.

Our managed hosting can save a substantial amount of developer time and
resources. For most businesses, this ends up being the best value
option and the revenue goes to funding the maintenance and further
development of Keygen. So you’ll be supporting [Fair Source](https://fair.io)
software and getting a great service!

## Self hosting with Keygen CE

Keygen is a fair source software licensing and distribution API, and we have a
free (as in beer) [self-hosted solution][self-hosting]. Keygen Community
Edition is exactly the same code base as our managed solution, Keygen Cloud,
but with a less frequent release schedule (think of it as an LTS release).

Bug fixes and new features are released to Keygen Cloud several times
per week. Features are battle-tested in Keygen Cloud which allows us to fix
any bugs before the general self-hosted release. Every 6 months, we
combine all the changes into a new self-hosted release.

Keygen CE does lack a few features from Keygen Cloud, which are available
in Keygen EE.

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
license Keygen EE. It's ~~turtles~~ Keygens all the way down (we love
dogfooding our own products).

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

Keygen CE is a community supported project and there are **no guarantees** that
you will receive support from the creators of Keygen to troubleshoot your
self-hosting issues. Keygen offers **best-effort** support for Keygen CE. There
is [a community-supported Discord server][discord] and [a forum][forum] where
you can ask for help with self-hosting.

If you do need support guantantees, consider becoming a [Keygen Cloud][keygen-cloud]
customer, or [purchasing Keygen EE][sales].

## Developing

### Secrets

To generate a [secret key](https://guides.rubyonrails.org/security.html) for
the application, run:

```bash
export SECRET_KEY_BASE="$(openssl rand -hex 64)"
```

To generate [at-work encryption](https://guides.rubyonrails.org/active_record_encryption.html) secrets, run:

```bash
export ENCRYPTION_DETERMINISTIC_KEY="$(openssl rand -base64 32)"
export ENCRYPTION_PRIMARY_KEY="$(openssl rand -base64 32)"
export ENCRYPTION_KEY_DERIVATION_SALT="$(openssl rand -base64 32)"
```

### Setup

To install dependencies, run:

```bash
bundle
```

To setup Keygen, run:

```bash
bundle exec rails keygen:setup
```

### Seeding

To seed the database with sample data, run (optional):

```bash
bundle exec rails db:seed:development
```

### Running

To start the server, run:

```bash
bundle exec rails server
```

To start a worker, run:

```bash
bundle exec sidekiq
```

To start a console, run:

```bash
bundle exec rails console
```

### Testing

To setup the test environment, run:

```bash
bundle exec rake test:setup
```

To run the entire test suite, specs and features, run (takes ~20 mins on a 16-core CPU):

```bash
bundle exec rake test
```

To run Cucumber features, run:

```bash
bundle exec rake test:cucumber
bundle exec rake test:cucumber[features/api/v1/licenses/actions/validations.feature:369]
bundle exec rake test:cucumber[features/api/v1/licenses/actions/validations.feature]
bundle exec rake test:cucumber[features/api/v1/licenses]
```

To run Rspec specs, run:

```bash
bundle exec rake test:rspec
bundle exec rake test:rspec[spec/models/license_spec.rb:199]
bundle exec rake test:rspec[spec/models/license_spec.rb]
bundle exec rake test:rspec[spec/models]
```

## License

Keygen is licensed under the [Fair Core License](https://fcl.dev). The Fair
Core License, or FCL, provides the best balance between user freedom and
developer sustainability for a project like Keygen that monetizes via SaaS and
self-hosting. The FCL is a mostly-permissive non-compete [Fair Source](https://fair.io)
license that eventually contributes to Open Source after 2 years.

The 2-year timeframe applies to each software version made available, whether
through pushing a Git commit, tagging a release on GitHub, or publishing an
image to Docker Hub. After 2 years, the code licensed under the FCL becomes
Open Source under the Apache 2.0 license.

To obtain an Open Source version of Keygen, run the following:

```bash
git clone https://github.com/keygen-sh/keygen-api && cd keygen-api
git checkout `git rev-list -n 1 --before='2 years ago' master`
```

If the `LICENSE.md` file is FCL, and that code is 2 years old, you may use that
version under the Open Source terms of the change license, which is currently
the Apache 2.0 license.

You can...

1. self-host Keygen EE to license your enterprise applications.
2. embed Keygen CE in your on-premise applications.
3. run Keygen CE on a private network.
3. modify Keygen to add additional functionality.
4. fork Keygen into a private repo.

There's no clause that requires you to Open Source modifications made to Keygen
or other derivative works.

If the FCL happens to not work for your company or use-case, please [reach out][sales].

The license is available [here](https://keygen.sh/license/).

## Contributing

If you discover an issue, or are interested in a new feature, please open an
issue. If you want to contribute code, feel free to open a pull request. If the
PR is substantial, it may be beneficial to open an issue beforehand to discuss.

The CLA is available [here](https://keygen.sh/cla/).

## Security

We take security at Keygen very seriously. We perform annual pen-tests on our
code base and infrastructure. In addition, we regularly perform code audits.
Our most recent pen-test was performed by [Greg Molnar](https://greg.molnar.io/security-consultancy/),
an OSCP-certified security researcher in the Ruby and Rails community.

If you believe you've found a vulnerability, please see our [`SECURITY.md`](https://github.com/keygen-sh/keygen-api/blob/master/SECURITY.md)
file.

## Is it any good?

[Yes.](https://news.ycombinator.com/item?id=3067434)

[keygen-cloud]: https://keygen.sh
[self-hosting]: https://keygen.sh/docs/self-hosting/
[sponsor]: https://github.com/sponsors/ezekg
[support]: mailto:support@keygen.sh
[discord]: https://discord.gg/TRrhSaWSsN
[forum]: https://github.com/keygen-sh/community/discussions
[contribute]: https://keygen.sh/contrib/
[license]: https://keygen.sh/license/
[sales]: mailto:sales@keygen.sh
