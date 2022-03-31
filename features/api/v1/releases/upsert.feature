@api/v1
Feature: Upsert release

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
    When I send a PUT request to "/accounts/test1/releases"
    Then the response status should be "403"

  Scenario: Admin upserts a release for their account (new)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Manifest",
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "filesize": 512,
        "platform": "darwin",
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
    And the current account should have 1 "release"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release for their account (update)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Manifest",
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "filesize": 512,
        "platform": "darwin",
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
    And the current account should have 1 "release"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product upserts a release for their product (new)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "channel": "stable",
            "version": "2.0.0",
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Manifest",
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "filesize": 512,
        "platform": "darwin",
        "channel": "stable",
        "version": "2.0.0",
        "semver": {
          "major": 2,
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
    And the current account should have 1 "release"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product upserts a release for their product (update)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "version": "1.0.0"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "platform": "darwin",
            "channel": "stable",
            "version": "2.0.0",
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "platform": "darwin",
        "channel": "stable",
        "version": "2.0.0",
        "semver": {
          "major": 2,
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
    And the current account should have 1 "release"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product upserts a release for a different product (new)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "channel": "stable",
            "version": "2.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[1]"
              }
            }
          }
        }
      }
      """
    And the current account should have 0 "releases"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product upserts a release for a different product (update)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "channel": "stable",
            "version": "2.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 1 "release"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product upserts a release for a different product (transfer to self)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "channel": "stable",
            "version": "2.0.0",
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
    And the current account should have 2 "releases"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product upserts a release for a different product (transfer to other)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "release" for the first "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "channel": "stable",
            "version": "2.0.0",
            "metadata": {
              "sha512": "36022a3f0b4bb6f3cdf57276867a210dc81f5c5b2215abf8a93c81ad18fa6bf0b1e36ee24ab7517c9474a1ad445a403d4612899687cabf591f938004df105011"
            }
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 1 "release"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a duplicate release (by version, no conflict)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest.yml",
        "version": "1.0.0"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Duplicate Manfiest",
            "filename": "latest-mac.yml",
            "filetype": "yml",
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Duplicate Manfiest",
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "platform": "darwin",
        "channel": "stable",
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
    And the current account should have 2 "releases"
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a duplicate release (by version, with conflict)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | latest-darwin.yml         | yml      | darwin   | stable   |
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "macOS Manfiest",
            "filename": "latest-mac.yml",
            "filetype": ".yml",
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
    Then the response status should be "422"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "version already exists for 'darwin' platform with 'yml' filetype on 'stable' channel",
        "source": {
          "pointer": "/data/attributes/version"
        },
        "code": "VERSION_TAKEN"
      }
      """
    And the current account should have 1 "release"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a conflicting release (by version, with null platform)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                     | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | gems/prerelease_specs.4.8.gz | gz       |          | stable   |
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "filename": "gems/latest_specs.4.8.gz",
        "filetype": "gz",
        "version": "1.0.0",
        "platform": null,
        "channel": "stable"
      }
      """
    And the current account should have 2 "releases"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a conflicting release (by version, with null filetype)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | gems/prerelease_specs.4.8 |          | rubygems | stable   |
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "filename": "gems/latest_specs.4.8",
            "filetype": null,
            "version": "1.0.0",
            "platform": "rubygems",
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "filename": "gems/latest_specs.4.8",
        "filetype": null,
        "version": "1.0.0",
        "platform": "rubygems",
        "channel": "stable"
      }
      """
    And the current account should have 2 "releases"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a conflicting release (by version, with null platform and filetype)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | gems/prerelease_specs.4.8 |          |          | stable   |
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "filename": "gems/latest_specs.4.8",
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "filename": "gems/latest_specs.4.8",
        "filetype": null,
        "version": "1.0.0",
        "platform": null,
        "channel": "stable"
      }
      """
    And the current account should have 2 "releases"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a duplicate release (by filename)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "description": "a note"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Duplicate Manifest",
            "description": null,
            "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA==",
            "checksum": null,
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "platform": "darwin",
            "channel": "stable",
            "version": "1.0.1"
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Duplicate Manifest",
        "description": null,
        "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA==",
        "checksum": null,
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "platform": "darwin",
        "channel": "stable",
        "version": "1.0.1",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 1,
          "prerelease": null,
          "build": null
        }
      }
      """
    And the current account should have 1 "release"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a duplicate release (new platform)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | latest-mac.yml            | yml      | macos   | stable   |
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "filename": "latest-mac.yml",
            "filetype": "yml",
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "platform": "darwin",
        "channel": "stable",
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
    And the current account should have 2 "release-platforms"
    And the current account should have 1 "release"
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts an rc release (new)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "latest-linux.yml",
            "filetype": "yml",
            "filesize": 1342177280,
            "platform": "linux",
            "channel": "rc",
            "version": "1.0.0-rc.1"
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": null,
        "filename": "latest-linux.yml",
        "filetype": "yml",
        "filesize": 1342177280,
        "platform": "linux",
        "channel": "rc",
        "version": "1.0.0-rc.1",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": "rc.1",
          "build": null
        }
      }
      """
    And the current account should have 1 "release"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts an rc release (update)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "name": "Latest Release (Linux)",
        "filename": "latest-linux.yml",
        "version": "1.0.0-rc.1"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "latest-linux.yml",
            "filetype": "yml",
            "filesize": 1342177280,
            "platform": "linux",
            "channel": "rc",
            "version": "1.0.0-rc.2"
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": null,
        "filename": "latest-linux.yml",
        "filetype": "yml",
        "filesize": 1342177280,
        "platform": "linux",
        "channel": "rc",
        "version": "1.0.0-rc.2",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": "rc.2",
          "build": null
        }
      }
      """
    And the current account should have 1 "release"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts an alpha release (new)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 2 "releases"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-windows.yml",
            "filetype": "yml",
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Manifest",
        "name": "Manifest",
        "filename": "latest-windows.yml",
        "filetype": "yml",
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
    And the current account should have 3 "releases"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts an alpha release (update)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-windows.yml",
        "filesize": 1024,
        "version": "1.0.0-alpha.1"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Manifest",
            "filename": "latest-windows.yml",
            "filetype": "yml",
            "platform": "win32",
            "channel": "alpha",
            "version": "1.0.0-alpha.2"
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Manifest",
        "filename": "latest-windows.yml",
        "filetype": "yml",
        "filesize": 1024,
        "platform": "win32",
        "channel": "alpha",
        "version": "1.0.0-alpha.2",
        "semver": {
          "major": 1,
          "minor": 0,
          "patch": 0,
          "prerelease": "alpha.2",
          "build": null
        }
      }
      """
    And the current account should have 1 "release"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a beta release (new)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "latest.yml",
            "filetype": "yml",
            "version": "2.11.0-beta.1",
            "platform": "linux",
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": null,
        "filename": "latest.yml",
        "filetype": "yml",
        "version": "2.11.0-beta.1",
        "platform": "linux",
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

  Scenario: Admin upserts a beta release (update)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest.yml"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "latest.yml",
            "filetype": "yml",
            "version": "2.11.0-beta.1",
            "platform": "linux",
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": null,
        "filename": "latest.yml",
        "filetype": "yml",
        "version": "2.11.0-beta.1",
        "platform": "linux",
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

  Scenario: Admin upserts a dev release (new)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "product.tar.gz",
            "filetype": "tar.gz",
            "filesize": 1342177280,
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": null,
        "filename": "product.tar.gz",
        "filetype": "tar.gz",
        "filesize": 1342177280,
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

  Scenario: Admin upserts a dev release (update)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "product.tar.gz"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null,
            "filename": "product.tar.gz",
            "filetype": "tar.gz",
            "filesize": null,
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": null,
        "filename": "product.tar.gz",
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

  Scenario: Admin upserts an alpha release on the stable channel
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-alpha.tar.gz"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Alpha Release",
            "filename": "latest-alpha.tar.gz",
            "filetype": "tar.gz",
            "platform": "linux",
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
    And the JSON response should be an array of 1 error
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

  Scenario: Admin upserts an alpha release on the beta channel
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
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
    And the JSON response should be an array of 1 error
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

  Scenario: Admin upserts a release with a mismatched filetype
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
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
    And the JSON response should be an array of 1 error
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

  Scenario: Admin upserts a release with an invalid version (not a semver)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
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
    And the JSON response should be an array of 1 error
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

  Scenario: Admin upserts a release with an invalid version (v prefix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
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
    And the JSON response should be an array of 1 error
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

  Scenario: Admin upserts a release with entitlement constraints (new)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Product Version 2",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "version": "2.0.0",
            "platform": "darwin",
            "channel": "stable"
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
    And the JSON response should be a "release"
    And the current account should have 2 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with entitlement constraints (update, new entitlement)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "version": "1.0.0"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Product Version 2",
            "filename": "latest-mac.yml",
            "filetype": ".yml",
            "version": "2.0.0",
            "platform": "darwin",
            "channel": "stable"
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
    Then the response status should be "200"
    And the JSON response should be a "release"
    And the current account should have 2 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with an invalid channel
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
            "name": "Product Version 2",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "version": "2.0.0",
            "platform": "darwin",
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
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be one of: stable, rc, beta, alpha, dev (received latest)",
        "source": {
          "pointer": "/data/attributes/channel"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with entitlement constraints (update, entitlement conflict)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "version": "1.0.0"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Product Version 2",
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "version": "2.0.0",
            "platform": "darwin",
            "channel": "stable"
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
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "release"
    And the current account should have 1 "release-entitlement-constraint"
    And the current account should have 3 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with entitlement constraints that belong to another account
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
    When I send a PUT request to "/accounts/test1/releases" with the following:
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
    And the JSON response should be an array of errors
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

  Scenario: Admin upserts a release with a null platform
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "gems/latest_specs.4.8.gz",
        "platform": null
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem Manifest: Latest Spec",
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Rubygem Manifest: Latest Spec",
        "filename": "gems/latest_specs.4.8.gz",
        "filetype": "gz",
        "version": "1.0.0",
        "platform": null,
        "channel": "stable"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with an empty platform (coalesce to null)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "gems/latest_specs.4.8.gz",
        "platform": null
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem Manifest: Latest Spec",
            "filename": "gems/latest_specs.4.8.gz",
            "filetype": "gz",
            "version": "1.0.0",
            "platform": "",
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Rubygem Manifest: Latest Spec",
        "filename": "gems/latest_specs.4.8.gz",
        "filetype": "gz",
        "version": "1.0.0",
        "platform": null,
        "channel": "stable"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with a null filetype
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "gems/specs.4.8",
        "filetype": null,
        "platform": null
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
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
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with an empty filetype (coalesce to null)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "gems/specs.4.8",
        "filetype": null,
        "platform": null
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem Manifest: Spec",
            "filename": "gems/specs.4.8",
            "filetype": "",
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
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
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
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with a null channel
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "gems/hello.gem"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem: Hello",
            "filename": "gems/hello.gem",
            "filetype": "gem",
            "version": "1.0.0",
            "platform": null,
            "channel": null
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
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "pointer": "/data/attributes/channel"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin upserts a release with an empty channel (coalesce to null)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      {
        "filename": "gems/hello.gem"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases" with the following:
      """
      {
        "data": {
          "type": "release",
          "attributes": {
            "name": "Rubygem: Hello",
            "filename": "gems/hello.gem",
            "filetype": "gem",
            "version": "1.0.0",
            "platform": null,
            "channel": ""
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
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be one of: stable, rc, beta, alpha, dev (received )",
        "source": {
          "pointer": "/data/attributes/channel"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
