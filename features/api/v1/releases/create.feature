@api/v1
Feature: Create release

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON
    # TODO(ezekg) Remove after we switch new accounts to v1.1
    And I use API version "1.1"

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases"
    Then the response status should be "403"

  Scenario: Admin creates a new release for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 14 "releases"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "channel": "stable",
            "tag": "application@v1.0.0",
            "version": "1.0.0",
            "metadata": {
              "shasums": [
                "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
              ]
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Launch Release",
        "channel": "stable",
        "status": "DRAFT",
        "tag": "application@v1.0.0",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "shasums": [
            "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
          ]
        }
      }
      """
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[14]/artifacts" }
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a new packaged release for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 14 "releases"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Package Release",
            "channel": "stable",
            "tag": "pkg@v1.0.0",
            "version": "1.0.0",
            "metadata": {
              "shasums": [
                "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
              ]
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            },
            "package": {
              "data": {
                "type": "packages",
                "id": "$packages[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Package Release",
        "channel": "stable",
        "status": "DRAFT",
        "tag": "pkg@v1.0.0",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "shasums": [
            "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
          ]
        }
      }
      """
    And the response body should be a "release" with the following relationships:
      """
      {
        "package": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[14]/package" },
          "data": { "type": "packages", "id": "$packages[0]" }
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release for a package of another product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "package"
    And the current account has 14 "releases"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Bad Release",
            "channel": "stable",
            "version": "1.0.0"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            },
            "package": {
              "data": {
                "type": "packages",
                "id": "$packages[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
          "title": "Unprocessable resource",
          "detail": "package product must match release product",
          "code": "PACKAGE_NOT_ALLOWED",
          "source": {
            "pointer": "/data/relationships/package"
          }
        }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a new release for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 14 "releases"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "channel": "stable",
            "version": "1.0.0",
            "tag": "latest",
            "metadata": {
              "shasums": [
                "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
              ]
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a new release for their account (free tier, limit not reached)
    Given the account "test1" is on a free tier
    And the account "test1" is subscribed
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 3 "releases"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "channel": "stable",
            "version": "1.0.0",
            "metadata": {
              "shasums": [
                "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
              ]
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Launch Release",
        "channel": "stable",
        "status": "DRAFT",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "shasums": [
            "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
          ]
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a new release for their account (free tier, limit reached)
    Given the account "test1" is on a free tier
    And the account "test1" is subscribed
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 10 "releases"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "channel": "stable",
            "version": "1.0.0",
            "metadata": {
              "shasums": [
                "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
              ]
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "Your tier's release limit of 10 has been reached for your account. Please upgrade to a paid tier and add a payment method at https://app.keygen.sh/billing.",
        "source": {
          "pointer": "/data/relationships/account"
        },
        "code": "ACCOUNT_RELEASE_LIMIT_EXCEEDED"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a draft release for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "channel": "stable",
            "status": "DRAFT",
            "tag": "application@v1.0.0",
            "version": "1.0.0"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Launch Release",
        "channel": "stable",
        "status": "DRAFT",
        "tag": "application@v1.0.0",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a published release for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "channel": "stable",
            "status": "PUBLISHED",
            "tag": "application@v1.0.0",
            "version": "1.0.0"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Launch Release",
        "channel": "stable",
        "status": "PUBLISHED",
        "tag": "application@v1.0.0",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a yanked release for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "channel": "stable",
            "status": "YANKED",
            "tag": "application@v1.0.0",
            "version": "1.0.0"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is invalid",
        "source": {
          "pointer": "/data/attributes/status"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate release (by tag)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      { "tag": "v1.0.0" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Duplicate Release",
            "channel": "stable",
            "version": "1.0.0",
            "tag": "v1.0.0"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "tag already exists",
        "code": "TAG_TAKEN",
        "source": {
          "pointer": "/data/attributes/tag"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate release (by version)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      { "version": "1.0.0" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Duplicate Release",
            "channel": "stable",
            "version": "1.0.0"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "version already exists",
        "code": "VERSION_TAKEN",
        "source": {
          "pointer": "/data/attributes/version"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a somewhat duplicate release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      { "version": "1.0.0-beta" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Duplicate Release",
            "channel": "beta",
            "version": "1.0.0-beta.1"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Admin creates an rc release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "channel": "rc",
            "version": "1.0.0-rc.99"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": null,
        "description": null,
        "channel": "rc",
        "version": "1.0.0-rc.99",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": "rc.99",
          "build": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an alpha release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Alpha Release",
            "description": null,
            "channel": "alpha",
            "version": "1.0.0-alpha.1"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Alpha Release",
        "description": null,
        "channel": "alpha",
        "version": "1.0.0-alpha.1",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": "alpha.1",
          "build": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a beta release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "version": "2.11.0-beta.1",
            "channel": "beta"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": null,
        "version": "2.11.0-beta.1",
        "channel": "beta",
        "semver": {
          "major": 2,
          "minor": 11,
          "patch": 0,
          "prerelease": "beta.1",
          "build": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a dev release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "version": "3.0.0-dev.9+build.93214",
            "channel": "dev",
            "metadata": {
              "contributors": ["@ezekg"]
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": null,
        "channel": "dev",
        "version": "3.0.0-dev.9+build.93214",
        "semver": {
          "major": 3,
          "minor": 0,
          "patch": 0,
          "prerelease": "dev.9",
          "build": "build.93214"
        },
        "metadata": {
          "contributors": ["@ezekg"]
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an alpha release on the stable channel
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Alpha Release",
            "channel": "stable",
            "version": "1.0.0-alpha.1"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "version does not match stable channel (expected x.y.z got 1.0.0-alpha.1)",
        "code": "VERSION_CHANNEL_INVALID",
        "source": {
          "pointer": "/data/attributes/version"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an alpha release on the beta channel
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Alpha Release",
            "version": "1.0.0-alpha.1",
            "channel": "beta"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "version does not match prerelease channel (expected x.y.z-beta.n got 1.0.0-alpha.1)",
        "code": "VERSION_CHANNEL_INVALID",
        "source": {
          "pointer": "/data/attributes/version"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release with an invalid version (not a semver)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Bad Version: Invalid",
            "version": "1.2.34.56789",
            "channel": "stable"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid version",
        "code": "VERSION_INVALID",
        "source": {
          "pointer": "/data/attributes/version"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release with an invalid version (v prefix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Bad Version: Prefix",
            "version": "v1.2.34",
            "channel": "stable"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid version",
        "code": "VERSION_INVALID",
        "source": {
          "pointer": "/data/attributes/version"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a shared release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 "product"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "version": "1.0.0-dev.42",
            "channel": "dev"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "environments",
                "id": "$environments[0]"
              }
            },
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": null,
        "channel": "dev",
        "version": "1.0.0-dev.42",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": "dev.42",
          "build": null
        }
      }
      """
    And the response body should be an "release" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release with entitlement constraints
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Product Version 2 (Beta)",
            "version": "2.0.0-alpha1",
            "channel": "alpha"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "product",
                "id": "$products[0]"
              }
            },
            "constraints": {
              "data": [
                {
                  "type": "constraint",
                  "relationships": {
                    "entitlement": {
                      "data": { "type": "entitlement", "id": "$entitlements[0]" }
                    }
                  }
                },
                {
                  "type": "constraint",
                  "relationships": {
                    "entitlement": {
                      "data": { "type": "entitlement", "id": "$entitlements[1]" }
                    }
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release"
    And the current account should have 2 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release with an invalid channel
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Bad Version: Prefix",
            "version": "1.2.34",
            "channel": "latest"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is invalid",
        "source": {
          "pointer": "/data/attributes/channel"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release with entitlement constraints that belong to another account
    Given the account "test2" has 2 "entitlements"
    And the first "entitlement" of account "test2" has the following attributes:
      """
      { "id": "2f9397b0-bbde-4219-a761-1307f338261f" }
      """
    And the second "entitlement" of account "test2" has the following attributes:
      """
      { "id": "481cc294-3f91-4efe-b471-90d14ecd5887" }
      """
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Product Version 2 (Beta)",
            "version": "2.0.0-alpha1",
            "channel": "alpha"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "product",
                "id": "$products[0]"
              }
            },
            "constraints": {
              "data": [
                {
                  "type": "constraint",
                  "relationships": {
                    "entitlement": {
                      "data": { "type": "entitlement", "id": "2f9397b0-bbde-4219-a761-1307f338261f" }
                    }
                  }
                },
                {
                  "type": "constraint",
                  "relationships": {
                    "entitlement": {
                      "data": { "type": "entitlement", "id": "481cc294-3f91-4efe-b471-90d14ecd5887" }
                    }
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "CONSTRAINTS_ENTITLEMENT_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/constraints/data/0/relationships/entitlement"
        }
      }
      """
    And the second error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "CONSTRAINTS_ENTITLEMENT_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/constraints/data/1/relationships/entitlement"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a new isolated release
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "product"
    And the current account has 5 isolated "releases"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Isolated Release",
            "channel": "stable",
            "tag": "iso@v1.0.0",
            "version": "1.0.0",
            "metadata": {
              "shasums": [
                "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
              ]
            }
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[0]"
              }
            },
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Isolated Release",
        "channel": "stable",
        "status": "DRAFT",
        "tag": "iso@v1.0.0",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "shasums": [
            "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
          ]
        }
      }
      """
    And the response body should be a "release" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": {
            "type": "environments",
            "id": "$environments[0]"
          }
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates a new release
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 5 "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Product Release",
            "channel": "stable",
            "tag": "prod@v1.0.0",
            "version": "1.0.0",
            "metadata": {
              "shasums": [
                "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
              ]
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Product Release",
        "channel": "stable",
        "status": "DRAFT",
        "tag": "prod@v1.0.0",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "shasums": [
            "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
          ]
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
