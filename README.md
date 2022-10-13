# Keygen

Keygen is an open source software licensing and distribution API built
by developers for developers. Easily add license key validation, entitlements,
and device activation to your business's desktop apps, server applications,
on-premise software, and other products using Keygen.

## Software licensing for everyone

Years ago, I was building desktop apps and I couldn't believe how complicated
it was to add licensing to a software product. From not being able to
price out options (because they didn't show their pricing!), to not
being able to access adequate documentation. Everything was
enterprise (tm), and built on XML.

Frankly, the state of software licensing sucked.

I knew there had to be a better way.

That's where Keygen comes in. Self-hosted, or hosted by us. Keygen is
an API-driven software licensing back-end, ready to be deployed on
your own domain or inside of a private network.

With Keygen, you can have full control of your data.

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

## Self hosting with Keygen OSS

Keygen is a fully open source software licensing and distribution API, and
we have a free (as in beer) [self-hosted solution][keygen-oss]. It’s exactly
the same product as our managed cloud solution, but with a less frequent
release schedule (think of it as an LTS release).

Bug fixes and new features are released to the cloud version several times
per week. Features are battle-tested in the cloud which allows us to fix
any bugs before the general self-hosted release. Every six months, we
combine all the changes into a new self-hosted release.

Interested in self-hosting Keygen? Take a look at our [self-hosting docs][keygen-oss].

## Sustainability

Our only sources of funding for Keygen is our premium, managed service for running
Keygen in the cloud, and premium support contracts. But if you're looking for
an alternative way to support the project, we've put together [some sponsorship
packages][sponsoring].

If you choose to self-host Keygen, you can become a sponsor, which is a great
way to give back to the community and to contribute to the long-term
sustainability of the project.

## Support

Keygen OSS is a community supported project and there are no guarantees that
you will get support from the creators of Keygen to troubleshoot your
self-hosting issues. There is [a community supported forum][forum] where you
can ask for help.

If you do need a support guantantees, you can purchase [a premium support
package][support].

## Technology

Keygen is a standard Ruby/Rails application, backed by PostgreSQL and Redis.

## Contributors

For anyone wishing to contribute to Keygen, we recommend taking a look at
[our contributor guide][contributing].

## Developing

### Setup

Running the application requires a Postgres database via `DATABASE_RUL` and
a Redis instance via `REDIS_URL`.

To initialize the database, run:

```bash
rails db:setup
rails db:seed
```

### Running

To run the application, run:

```bash
rails s
```

### Testing

To run the entire test suite, specs and features, run:

```bash
rake test
```

To run features, run:

```bash
rake parallel:features
```

To run specs, run:

```bash
rake parallel:specs
```

## License

Keygen is licensed under [the Elastic License 2.0 (ELv2)][license].

[keygen-cloud]:
[keygen-oss]:
[sponsoring]:
[support]:
[forum]:
[contributing]:
[license]:
