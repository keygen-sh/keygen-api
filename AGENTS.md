# Keygen

This file provides guidance to AI coding agents working with the Keygen codebase, with a focus on **writing, selecting, and running tests correctly**.

**Read this before running or modifying tests.**

---

Terminology used throughout this document and in conversation:

* **Integration test** and **unit test** both refer to an RSpec spec (`spec/**/*_spec.rb`).
* **System test** refers to a Cucumber feature (`features/**/*.feature`).

## 1. Core rules

1. **Always run tests via the `rake` test harness. Never invoke `rspec` or `cucumber` directly.** The `rake test` task configures `parallel_tests`, `TEST_ENV_NUMBER`, the DB connection pool, and `RAILS_ENV`. Bypassing it will misconfigure the test environment.

   * Correct: `bundle exec rake test:rspec[...]`
   * Incorrect: `bundle exec rspec ...`

2. **Set environment variables explicitly when behavior depends on edition, mode, host, or Clickhouse.** Do not rely on defaults, as you may not know the current environment you're working in.

3. **If a test appears not to execute, check the skip count and skip reasons first.** Skips are counted and reported in the formatter output. Most "not running" cases are tag/metadata mismatches, not genuine failures.

4. **Match tags/metadata to the environment you're running under.**

5. **Prefer targeted test runs over full suite runs.**

## 2. Editions and modes

Behavior depends on these env vars:

* `KEYGEN_EDITION`: `CE` or `EE`. Defaults to `CE`.
* `KEYGEN_MODE`: `singleplayer` or `multiplayer`. Defaults to `singleplayer`.
* `KEYGEN_HOST`: the API host. Cloud is detected via `Keygen.cloud?`.

### Valid combinations

| Edition | Mode                          | Result                        |
| ------- | ----------------------------- | ----------------------------- |
| CE      | singleplayer                  | Single-tenant CE              |
| EE      | singleplayer                  | Single-tenant EE              |
| EE      | multiplayer                   | Multi-tenant EE               |
| EE      | multiplayer + `api.keygen.sh` | Multi-tenant Cloud EE variant |

**Invalid:** CE + multiplayer (excluded in CI).

The `Keygen.ee { ... }` runtime helper yields only in EE and is a no-op in CE. The block may optionally take the current EE license and license file as arguments.

## 3. Test selection rules

Tests are frequently filtered by tags and metadata. This is expected behavior.

### 3.1 Cucumber tags

| Tag           | Runs when                  |
| ------------- | -------------------------- |
| `@ee`         | Only in EE                 |
| `@ce`         | Only in CE                 |
| `@mp`         | Only in multiplayer        |
| `@sp`         | Only in singleplayer       |
| `@clickhouse` | Only if Clickhouse enabled |
| `@skip`       | Never                      |

### 3.2 RSpec metadata

| Metadata                 | Behavior                          |
| ------------------------ | --------------------------------- |
| `only: :ee` / `:only_ee` | EE only (skipped in CE)           |
| `only: :ce` / `:only_ce` | CE only (skipped in EE)           |
| `skip: :ee`              | Skipped in EE                     |
| `skip: :ce`              | Skipped in CE                     |
| `:only_clickhouse`       | Skipped unless Clickhouse enabled |

Both symbol forms are valid: `describe Foo, :only_ee do` and `describe Foo, only: :ee do`.

## 4. Writing tests

### 4.1 Edition-aware tests

Two **RSpec-only** scenario helpers are available. Each wraps its block in a `describe`/`context`, sets `KEYGEN_EDITION`, and (for EE) stubs the current EE license file with a mocked license:

```ruby
within_ee do
  # EE-specific behavior
end

within_ce do
  # CE-specific behavior
end
```

`within_ee` accepts `expiry:`, `issued:`, and `entitlements:` kwargs. The default entitlements include `request_logs`, `event_logs`, `permissions`, `environments`, and `multiplayer` — override `entitlements:` to test EE without one of them (e.g. strict singleplayer EE).

In Cucumber, use `@ee` / `@ce` tags instead — these helpers do not exist there.

### 4.2 Avoid implicit assumptions

Avoid:

* Assuming CE and singleplayer will be used implicitly (depends on existing env)
* Assuming EE features are enabled at the top level of a spec
* Assuming Clickhouse is enabled

Prefer:

* Explicit environment configuration
* Explicit edition and mode
* Explicit tags or metadata

## 5. Clickhouse

Clickhouse is an optional secondary database. Its config is always present in the `test` environment, but it must still be explicitly **enabled** at runtime via:

```bash
CLICKHOUSE_DATABASE_ENABLED=1
```

Without this env var:

* RSpec examples tagged `:only_clickhouse` are skipped.
* Cucumber scenarios tagged `@clickhouse` are skipped.

Enable Clickhouse when testing analytics, logs, or event pipelines.

## 6. Managing test environment

### Setup

This is typically not required unless the databases have not been initialized (rare).

```bash
bundle exec rake test:setup
```

### Full suite (RSpec + Cucumber)

This is typically not recommended. Prefer running targeted tests (see section 7).

```bash
bundle exec rake test
```

### Reset

This is typically not required unless the databases have new migrations.

```bash
bundle exec rake test:reset
```

## 7. Targeted test execution

### RSpec

```bash
bundle exec rake test:rspec
bundle exec rake test:rspec[spec/models]                         # all specs in dir
bundle exec rake test:rspec[spec/models/license_spec.rb]         # specific file
bundle exec rake test:rspec[spec/models/license_spec.rb:199]     # specific line
bundle exec rake test:rspec[spec/models/license_spec.rb:199:210] # multiple lines
bundle exec rake test:rspec[spec/models/license_spec.rb[1:2:3]]  # specific example
```

### Cucumber

```bash
bundle exec rake test:cucumber
bundle exec rake test:cucumber[features/api/v1/licenses]                         # all features in dir
bundle exec rake test:cucumber[features/api/v1/licenses/create.feature]          # specific file
bundle exec rake test:cucumber[features/api/v1/licenses/create.feature:20]       # specific line
bundle exec rake test:cucumber[features/api/v1/licenses/create.feature:10:20:30] # multiple lines
```

### Notes

* Line-number / example-ID patterns bypass `parallel_tests` and fall back to serial execution. This is expected and handled by the `rake test` task.
* Multiple line numbers joined by colons (e.g. `foo_spec.rb:10:20:30`, `foo.feature:10:20:30`) are supported for both RSpec and Cucumber.

## 8. Running under a specific context

Prefix the `rake` invocation with the env vars for the combination you want to exercise.

```bash
# CE, singleplayer (self-hosted)
KEYGEN_EDITION=CE KEYGEN_MODE=singleplayer \
  bundle exec rake test:rspec[spec/models/license_spec.rb]

# EE, singleplayer (self-hosted)
KEYGEN_EDITION=EE KEYGEN_MODE=singleplayer \
  bundle exec rake test:rspec[spec/models/license_spec.rb]

# EE, multiplayer (self-hosted)
KEYGEN_EDITION=EE KEYGEN_MODE=multiplayer \
  bundle exec rake test:cucumber[features/api/v1/accounts]

# EE, multiplayer, api.keygen.sh (Cloud)
KEYGEN_EDITION=EE KEYGEN_MODE=multiplayer KEYGEN_HOST=api.keygen.sh \
  bundle exec rake test:cucumber[features/cnames/domains.feature]

# With Clickhouse
CLICKHOUSE_DATABASE_ENABLED=1 KEYGEN_EDITION=EE KEYGEN_MODE=multiplayer \
  bundle exec rake test:rspec[spec/workers/record_machine_sparks_worker_spec.rb]
```

If a scenario or example is tagged for an edition, mode, or Clickhouse and you run it under the wrong combination, it will be **skipped**, not failed. If tests you expect to run aren't running, double-check the tags/metadata against the env vars you passed.

## 9. Debugging checklist

Before investigating a failure or a missing test, check in order:

1. **Was `rake test` used?** Required for correct environment setup and parallelization.
2. **Was the test skipped?** Inspect the skip count and reasons in the output.
3. **Is the edition correct?** E.g. `KEYGEN_EDITION=CE|EE`.
4. **Is the mode correct?** E.g. `KEYGEN_MODE=singleplayer|multiplayer`.
5. **Is the host correct (for Cloud)?** E.g. `KEYGEN_HOST=api.keygen.sh`.
6. **Is Clickhouse required but disabled?** Set `CLICKHOUSE_DATABASE_ENABLED=1`.
7. **Is the schema outdated?** Run `bundle exec rake test:reset`.
