@api/v1
Feature: Generate authentication token for product
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
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin generates a product token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "product-token",
        "expiry": null
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a named product token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Server Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      { "name": "Server Token" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Global admin generates a shared token for a global product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And the current account has 1 global "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Shared Token"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
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
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/relationships/environment"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Shared admin generates a token for a shared product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 shared "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Shared Token"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
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
        "detail": "is unsupported",
        "code": "ENVIRONMENT_NOT_SUPPORTED",
        "source": {
          "header": "Keygen-Environment"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin generates a token for an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 isolated "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Isolated Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin generates a token for an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 isolated "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Isolated Token"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin generates a token for an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "admin"
    And the current account has 1 isolated "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Isolated Token"
          }
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin generates a token for an shared product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 shared "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Shared Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin generates a token for a shared product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 shared "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Shared Token"
          }
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin generates a token for a shared product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And the current account has 1 shared "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Shared Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin generates a token for the global product
    Given the current account is "test1"
    And the current account has 1 global "admin"
    And the current account has 1 global "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Global Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin generates a token for the global product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 global "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Global Token"
          }
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin generates a token for the global product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 global "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Global Token"
          }
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for the global product (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 isolated "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Global Token"
          },
          "relationships": {
            "environment": {
              "data": null
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for an isolated product (from a shared environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 shared "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Isolated Token"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for a shared product (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 isolated "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Shared Token"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for a shared product (from the global environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And the current account has 1 global "product"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Shared Token"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment generates a token for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And I am the last environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Isolated Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin generates a product token with custom permissions (standard tier, CE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin generates a product token with custom permissions (ent tier, CE)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with custom permissions (standard tier, EE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.suspend",
          "license.validate",
          "machine.create",
          "machine.read",
          "machine.update"
        ]
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with custom permissions (ent tier, EE)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.suspend",
          "license.validate",
          "machine.create",
          "machine.read",
          "machine.update"
        ]
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with permissions that exceed the product's permissions (standard tier)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "policy.create",
              "policy.update",
              "policy.read",
              "license.create",
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with permissions that exceed the product's permissions (ent tier)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "policy.create",
              "policy.update",
              "policy.read",
              "license.create",
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with unsupported permissions (standard tier)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["account.billing.read"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with unsupported permissions (ent tier)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["account.billing.read"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with invalid permissions (standard tier)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
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
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with invalid permissions (ent tier)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products/$0/tokens" with the following:
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
    And the response body should be an array of 1 errors
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with permissions for product with wildcard permission (standard tier)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product" with the following:
      """
      { "permissions": ["*"] }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "policy.create",
              "policy.update",
              "policy.read",
              "license.create",
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "permissions": [
          "license.create",
          "license.read",
          "license.suspend",
          "license.validate",
          "machine.create",
          "machine.read",
          "machine.update",
          "policy.create",
          "policy.read",
          "policy.update"
        ]
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a product token with permissions for product with wildcard permission (ent tier)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product" with the following:
      """
      { "permissions": ["*"] }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "policy.create",
              "policy.update",
              "policy.read",
              "license.create",
              "license.read",
              "license.validate",
              "license.suspend",
              "machine.create",
              "machine.update",
              "machine.read"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "permissions": [
          "license.create",
          "license.read",
          "license.suspend",
          "license.validate",
          "machine.create",
          "machine.read",
          "machine.update",
          "policy.create",
          "policy.read",
          "policy.update"
        ]
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to generate a token
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "403"

  Scenario: Product attempts to generate a token for another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$1/tokens"
    Then the response status should be "404"

  Scenario: License attempts to generate token for their product
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$2/tokens"
    Then the response status should be "403"

  Scenario: License attempts to generate token for a product
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "404"

  Scenario: User attempts to generate token for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the last "license" is associated to the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "403"

  Scenario: User attempts to generate token for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "404"

  Scenario: Admin attempts to generate a product token for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test2/products/$0/tokens"
    Then the response status should be "401"

  Scenario: Admin requests tokens for one of their products
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "200"
    And the response body should be an array of 1 "token"

  Scenario: Product requests their tokens
    Given the current account is "test1"
    And the current account has 5 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the first "licenses" has the following attributes:
      """
      { "userId": "$users[4]" }
      """
    And the second "licenses" has the following attributes:
      """
      { "userId": "$users[5]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "200"
    And the response body should be an array of 1 "token"

  Scenario: Product requests tokens for another product
    Given the current account is "test1"
    And the current account has 5 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the first "licenses" has the following attributes:
      """
      { "userId": "$users[4]" }
      """
    And the second "licenses" has the following attributes:
      """
      { "userId": "$users[5]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$2/tokens"
    Then the response status should be "404"

  Scenario: License requests tokens for their product
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$2/tokens"
    Then the response status should be "403"

  Scenario: License requests tokens for a product
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "404"

  Scenario: User requests tokens for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 3 "licenses" for the last "policy"
    And the last "license" is associated to the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "403"

  Scenario: User requests tokens for a product
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 6 "users"
    And the current account has 1 "token" for each "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/tokens"
    Then the response status should be "404"
