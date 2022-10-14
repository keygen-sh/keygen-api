@api/v1
Feature: User tokens relationship
  Background:
    Given the following "plan" rows exist:
      | id                                   | name       |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Standard 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1      |
    Given the following "account" rows exist:
      | name   | slug  | plan_id                              |
      | Test 1 | test1 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Test 2 | test2 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Ent 1  | ent1  | 44c7918c-80ab-4a13-a831-a2c46cda85c6 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin generates an admin token (themself)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin generates an admin token (another)
    Given the current account is "test1"
    And the current account has 1 "admin"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "403"

  Scenario: Admin generates a user token (has password)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now"
    And the JSON response should be a "token" with the kind "user-token"
    And the JSON response should be a "token" with a token
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a user token (no password)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "passwordDigest": null }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now"
    And the JSON response should be a "token" with the kind "user-token"
    And the JSON response should be a "token" with a token
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a named user token
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Client Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      { "name": "Client Token" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a user token with a custom expiry (present)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "expiry": "2016-10-05T22:53:37.000Z"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a user token with a custom expiry (null)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "expiry": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now"
    And the JSON response should be a "token" with the kind "user-token"
    And the JSON response should be a "token" with a token
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Product generates a user token with custom permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["license.validate"]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ce
  Scenario: Product generates a user token with custom permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["license.validate"]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: /data/attributes/permissions"
      }
      """

  @ee
  Scenario: Product generates a user token with custom permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["license.validate"]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: /data/attributes/permissions"
      }
      """

  @ee
  Scenario: Product generates a user token with custom permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["license.validate"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "ent1"
    And the JSON response should be a "token" with the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product generates a user token with permissions that exceed the user's permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read",
              "machine.create",
              "machine.delete",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ee
  Scenario: Product generates a user token with permissions that exceed the user's permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read",
              "machine.create",
              "machine.delete",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "422"
    And the response should contain a valid signature header for "ent1"
    And the JSON response should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "unsupported permissions",
        "code": "PERMISSIONS_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/permissions"
        },
        "links": {
          "about": "https://keygen.sh/docs/api/tokens/#tokens-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product generates a user token with unsupported permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["product.create"]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ee
  Scenario: Product generates a user token with unsupported permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["product.create"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the response should contain a valid signature header for "ent1"
    And the JSON response should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "unsupported permissions",
        "code": "PERMISSIONS_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/permissions"
        },
        "links": {
          "about": "https://keygen.sh/docs/api/tokens/#tokens-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product generates a user token with invalid permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["foo.bar"]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ee
  Scenario: Product generates a user token with invalid permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["foo.bar"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the response should contain a valid signature header for "ent1"
    And the JSON response should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "unsupported permissions",
        "code": "PERMISSIONS_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/permissions"
        },
        "links": {
          "about": "https://keygen.sh/docs/api/tokens/#tokens-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product generates a user token with permissions for a user with wildcard permission (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["*"] }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read",
              "machine.create",
              "machine.delete",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ee
  Scenario: Product generates a user token with permissions for a user with wildcard permission (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["*"] }
      """
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read",
              "machine.create",
              "machine.delete",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.delete",
          "machine.read"
        ]
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "403"

  Scenario: User generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "403"

  Scenario: Anonymous generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "401"

  Scenario: Admin requests tokens for one of their users
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$3/tokens"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests tokens for one of their users
    Given the current account is "test1"
    And the current account has 5 "products"
    And the current account has 1 "token" for each "product"
    And I am a product of account "test1"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And the current account has 1 "token" for each "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"

  Scenario: Product requests tokens for another product's user
    Given the current account is "test1"
    And the current account has 5 "products"
    And the current account has 1 "token" for each "product"
    And I am a product of account "test1"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And the current account has 1 "token" for each "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$5/tokens"
    Then the response status should be "200"

  Scenario: License requests tokens for their user
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 6 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 1 "license" for each "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "403"

  Scenario: License requests tokens for a user
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 6 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "404"

  Scenario: User requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 6 "users"
    And the current account has 1 "token" for each "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: User requests tokens for another user
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 6 "users"
    And the current account has 1 "token" for each "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "404"

  Scenario: Anonymous requests a user's tokens
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "token" for each "user"
    And I am a user of account "test1"
    When I send a GET request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "401"
