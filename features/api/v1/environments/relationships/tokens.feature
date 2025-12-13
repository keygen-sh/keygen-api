@api/v1
@ee
Feature: Generate authentication token for environment
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
    And the current account has 1 "environment"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "403"

  Scenario: Isolated admin generates a token for an isolated environment (by ID)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    Then the response status should be "201"
    And the response body should be a "token" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be a "token" with the following attributes:
      """
      {
        "name": "Isolated Token",
        "kind": "environment-token",
        "expiry": null
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Isolated admin generates a token for an isolated environment (by code)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/isolated/tokens" with the following:
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
    Then the response status should be "201"
    And the response body should be a "token" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be a "token" with the following attributes:
      """
      {
        "name": "Isolated Token",
        "kind": "environment-token",
        "expiry": null
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Shared admin generates a token for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Global admin generates a token for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Shared admin generates a token for an shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    Then the response status should be "201"
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Isolated admin generates a token for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$1/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Global admin generates a token for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    Then the response status should be "201"
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Global admin generates a token for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Global admin generates a token for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a token for the nil environment (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a token for an isolated environment (from a shared environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a token for a shared environment (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a token for a shared environment (from the global environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with custom permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    Then the response status should be "201"
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with custom permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/environments/$0/tokens" with the following:
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
    Then the response status should be "201"
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with permissions that exceed the environment's permissions (standard tier)
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "environment" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with permissions that exceed the environment's permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 shared "environment" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with unsupported permissions (standard tier)
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with unsupported permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with invalid permissions (standard tier)
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with invalid permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/environments/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with permissions for environment with wildcard permission (standard tier)
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "environment" with the following:
      """
      { "permissions": ["*"] }
      """
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens" with the following:
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
    Then the response status should be "201"
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates an environment token with permissions for environment with wildcard permission (ent tier)
    Given the current account is "ent1"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 shared "environment" with the following:
      """
      { "permissions": ["*"] }
      """
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/environments/$0/tokens" with the following:
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
    Then the response status should be "201"
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Environment attempts to generate a token
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "403"

  Scenario: Environment attempts to generate a token (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$1/tokens"
    Then the response status should be "404"

  Scenario: Environment attempts to generate a token (in shared environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$1/tokens"
    Then the response status should be "401"

  Scenario: Product attempts to generate a token
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "product"
    And I am a product of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: Product attempts to generate a token for another environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "product"
    And I am a product of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: License attempts to generate token for their environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "token" for each "environment"
    And the current account has 1 shared "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: License attempts to generate token for another environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "token" for each "environment"
    And the current account has 1 isolated "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: User attempts to generate token for their environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "policy" for the last "environment"
    And the current account has 1 shared "user"
    And the current account has 1 shared "license" for the last "policy"
    And the last "license" is associated to the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: User attempts to generate token for another environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: Admin attempts to generate an environment token for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 1 shared "environment"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test2/environments/$0/tokens"
    Then the response status should be "401"

  Scenario: Admin requests tokens for one of their environments
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 5 isolated "users"
    And the current account has 1 isolated "token" for each "user"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "200"
    And the response body should be an array of 1 "token"

  Scenario: Environment requests their tokens
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "tokens" for each "environment"
    And the current account has 2 isolated "products"
    And the current account has 1 isolated "token" for each "product"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "200"
    And the response body should be an array of 2 "tokens"

  Scenario: Environment requests tokens for another environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 1 shared "product"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "401"

  Scenario: Product requests tokens for their environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 2 isolated "products"
    And the current account has 1 isolated "token" for each "product"
    And I am an product of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: Product requests tokens for another environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 1 shared "product"
    And I am an product of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: License requests tokens for their environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 2 isolated "licenses"
    And the current account has 1 isolated "token" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: License requests tokens for another environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 1 shared "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: User requests tokens for their environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 2 isolated "users"
    And the current account has 1 isolated "token" for each "user"
    And I am the last user of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"

  Scenario: User requests tokens for another environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 1 shared "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0/tokens"
    Then the response status should be "404"
