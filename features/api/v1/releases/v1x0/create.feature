@api/v1.0 @deprecated
Feature: Create release

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases"
    Then the response status should be "403"

  Scenario: Admin creates a new release for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Keygen v1.0",
            "filename": "Keygen-1.0.0.dmg",
            "filetype": "dmg",
            "filesize": 209715200,
            "platform": "darwin",
            "channel": "stable",
            "version": "1.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
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
        "name": "Keygen v1.0",
        "filename": "Keygen-1.0.0.dmg",
        "filetype": "dmg",
        "filesize": 209715200,
        "platform": "darwin",
        "channel": "stable",
        "status": "NOT_PUBLISHED",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
        }
      }
      """
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifact" },
          "data": { "type": "artifacts", "id": "$artifacts[0]" }
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a new release for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Keygen v1.0",
            "filename": "Keygen-1.0.0.dmg",
            "filetype": "dmg",
            "filesize": 209715200,
            "platform": "darwin",
            "channel": "stable",
            "version": "1.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
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
        "name": "Keygen v1.0",
        "filename": "Keygen-1.0.0.dmg",
        "filetype": "dmg",
        "filesize": 209715200,
        "platform": "darwin",
        "channel": "stable",
        "status": "NOT_PUBLISHED",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
        }
      }
      """
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifact" },
          "data": { "type": "artifacts", "id": "$artifacts[0]" }
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "filename": "Product-1.0.0.dmg",
            "filetype": "dmg",
            "filesize": 209715200,
            "platform": "darwin",
            "channel": "stable",
            "version": "1.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
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
        "filename": "Product-1.0.0.dmg",
        "filetype": "dmg",
        "filesize": 209715200,
        "platform": "darwin",
        "channel": "stable",
        "status": "NOT_PUBLISHED",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "filename": "Product-1.0.0.dmg",
            "filetype": "dmg",
            "filesize": 209715200,
            "platform": "darwin",
            "channel": "stable",
            "version": "1.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
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

  Scenario: Admin creates a new release for their account (non-lowercase filetype)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Launch Release",
            "description": "Our first release",
            "filename": "Product-1.0.0.AppImage",
            "filetype": ".AppImage",
            "filesize": 209715200,
            "platform": "linux",
            "channel": "stable",
            "version": "1.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
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
        "description": "Our first release",
        "filename": "Product-1.0.0.AppImage",
        "filetype": "appimage",
        "filesize": 209715200,
        "platform": "linux",
        "channel": "stable",
        "version": "1.0.0",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": null,
          "build": null
        },
        "metadata": {
          "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Duplicate Release",
            "filename": "Product-1.0.0.dmg",
            "filetype": "dmg",
            "platform": "darwin",
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
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
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
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate release (by filename)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "filename": "Product-1.0.0.dmg" }
      """
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Duplicate Release",
            "filename": "Product-1.0.0.dmg",
            "filetype": "dmg",
            "platform": "darwin",
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
    Then the response status should be "201"
    And the response body should be a "release" with the following attributes:
      """
      {
        "filename": "Product-1.0.0.dmg",
        "filetype": "dmg"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an rc release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            "filename": "Product-1.0.0-rc.99.zip",
            "filetype": "zip",
            "filesize": 1342177280,
            "platform": "macos",
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
        "signature": null,
        "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        "filename": "Product-1.0.0-rc.99.zip",
        "filetype": "zip",
        "filesize": 1342177280,
        "platform": "macos",
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Alpha Release",
            "description": null,
            "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA==",
            "checksum": null,
            "filename": "Product-1.0.0-alpha.1.exe",
            "filetype": "exe",
            "platform": "win32",
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
        "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA==",
        "checksum": null,
        "filename": "Product-1.0.0-alpha.1.exe",
        "filetype": "exe",
        "filesize": null,
        "platform": "win32",
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "Product-2.11.0-beta.1.tar.gz",
            "version": "2.11.0-beta.1",
            "platform": "linux",
            "filetype": "tar.gz",
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
        "filename": "Product-2.11.0-beta.1.tar.gz",
        "version": "2.11.0-beta.1",
        "platform": "linux",
        "filetype": "tar.gz",
        "channel": "beta",
        "filesize": null,
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "Product-3.0.0-dev.9+build.93214.tar.gz",
            "filetype": ".tar.gz",
            "version": "3.0.0-dev.9+build.93214",
            "platform": "linux",
            "channel": "dev",
            "metadata": {
              "sha256": "b6d094cb3f6a6855ec668f9ac8d2d33739d6a120ec7caca968d07c6bb667857b"
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
        "filename": "Product-3.0.0-dev.9+build.93214.tar.gz",
        "filetype": "tar.gz",
        "filesize": null,
        "platform": "linux",
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
          "sha256": "b6d094cb3f6a6855ec668f9ac8d2d33739d6a120ec7caca968d07c6bb667857b"
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Alpha Release",
            "filename": "Product-1.0.0-alpha.1.exe",
            "filetype": "exe",
            "platform": "win32",
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Alpha Release",
            "filename": "Product-1.0.0-alpha.1.exe",
            "version": "1.0.0-alpha.1",
            "platform": "win32",
            "filetype": "exe",
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

  Scenario: Admin creates a release with a mismatched filetype
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Release Candidate #1",
            "filename": "Product-2.0.0-rc.1.zip",
            "version": "2.0.0-rc.1",
            "platform": "win32",
            "filetype": "exe",
            "channel": "rc"
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
        "detail": "filename extension does not match filetype (expected exe)",
        "code": "FILENAME_EXTENSION_INVALID",
        "source": {
          "pointer": "/data/attributes/filename"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release without an extension in the filename
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "NPM Package Manifest",
            "filename": "@npm/module",
            "version": "1.0.0",
            "platform": "npm",
            "filetype": "json",
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
    Then the response status should be "201"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release with an invalid version (not a semver)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Bad Version: Invalid",
            "filename": "Product.zip",
            "version": "1.2.34.56789",
            "platform": "win32",
            "filetype": "zip",
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Bad Version: Prefix",
            "filename": "Product.zip",
            "version": "v1.2.34",
            "platform": "win32",
            "filetype": "zip",
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

  Scenario: Admin creates a release with entitlement constraints
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Product Version 2 (Beta)",
            "filename": "Product-2.0.0-alpha1.dmg",
            "version": "2.0.0-alpha1",
            "platform": "darwin",
            "filetype": "dmg",
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Bad Version: Prefix",
            "filename": "Product.zip",
            "version": "1.2.34",
            "platform": "win32",
            "filetype": "zip",
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Product Version 2 (Beta)",
            "filename": "Product-2.0.0-alpha1.dmg",
            "version": "2.0.0-alpha1",
            "platform": "darwin",
            "filetype": "dmg",
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

  Scenario: Admin creates a release with a null filetype
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem Manifest: Spec",
            "filename": "gems/specs.4.8",
            "filetype": null,
            "version": "1.0.0",
            "platform": null,
            "channel": "stable"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "product",
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
        "name": "Rubygem Manifest: Spec",
        "filename": "gems/specs.4.8",
        "filetype": null,
        "version": "1.0.0",
        "platform": null,
        "channel": "stable"
      }
      """
    And the current account should have 0 "platforms"
    And the current account should have 0 "filetypes"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a release with a null platform
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem Manifest: Latest",
            "filename": "gems/latest_specs.4.8.gz",
            "filetype": "gz",
            "version": "1.0.0",
            "platform": null,
            "channel": "stable"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "product",
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
        "name": "Rubygem Manifest: Latest",
        "filename": "gems/latest_specs.4.8.gz",
        "filetype": "gz",
        "version": "1.0.0",
        "platform": null,
        "channel": "stable"
      }
      """
    And the current account should have 0 "platforms"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate release with a null platform
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for the first "release"
    And the first "artifact" has the following attributes:
      """
      {
        "filename": "gems/latest_specs.4.8.gz",
        "platform": null
      }
      """
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem Manifest: Latest",
            "filename": "gems/latest_specs.4.8.gz",
            "filetype": "gz",
            "version": "1.0.0",
            "platform": null,
            "channel": "stable"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "product",
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
        "filename": "gems/latest_specs.4.8.gz",
        "platform": null
      }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate release with a null filetype
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for the first "release"
    And the first "artifact" has the following attributes:
      """
      {
        "filename": "gems/specs.4.8",
        "filetype": null,
        "platform": null
      }
      """
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem Manifest: Spec",
            "filename": "gems/specs.4.8",
            "filetype": null,
            "version": "1.0.0",
            "channel": "stable"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "product",
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
        "filename": "gems/specs.4.8",
        "filetype": null,
        "platform": null
      }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs
    And sidekiq should have 1 "request-log" job
