@api/v1
Feature: Generate authentication token for license
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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin generates a license token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": null,
        "maxActivations": null,
        "maxDeactivations": null,
        "activations": 0,
        "deactivations": 0
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a named license token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And the response body should be a "token" with the following attributes:
      """
      { "name": "Client Token" }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a license token with a max activation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxActivations": 1
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": null,
        "maxActivations": 1,
        "maxDeactivations": null,
        "activations": 0,
        "deactivations": 0
      }
      """

  Scenario: Admin generates a license token with a negative max activation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxActivations": -1
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
        "detail": "must be greater than or equal to 0",
        "source": {
          "pointer": "/data/attributes/maxActivations"
        },
        "code": "MAX_ACTIVATIONS_INVALID"
      }
      """

  Scenario: Admin generates a license token with a negative max deactivation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxDeactivations": -1
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
        "detail": "must be greater than or equal to 0",
        "source": {
          "pointer": "/data/attributes/maxDeactivations"
        },
        "code": "MAX_DEACTIVATIONS_INVALID"
      }
      """

  Scenario: Admin generates a license token with a set expiry
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": "2016-10-05T22:53:37.000Z",
        "maxActivations": null,
        "maxDeactivations": null,
        "activations": 0,
        "deactivations": 0
      }
      """

  Scenario: Admin generates a license token with a max deactivation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxDeactivations": 1
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": null,
        "maxActivations": null,
        "maxDeactivations": 1,
        "activations": 0,
        "deactivations": 0
      }
      """

  Scenario: Admin generates a license token but sends invalid attributes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "bearerId": "$users[0]",
            "bearerType": "users"
          }
        }
      }
      """
    Then the response status should be "400"

  Scenario: Product generates a license token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the response body should be a "token" with a nil expiry

  @ce
  Scenario: Global admin generates a shared token for a global license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And the current account has 1 global "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Shared admin generates a token for a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 shared "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin generates a token for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 isolated "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin generates a token for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 isolated "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin generates a token for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "admin"
    And the current account has 1 isolated "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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

  @ee
  Scenario: Shared admin generates a token for an shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 shared "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin generates a token for a shared license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 shared "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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

  @ee
  Scenario: Global admin generates a token for a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And the current account has 1 shared "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin generates a token for the global license
    Given the current account is "test1"
    And the current account has 1 global "admin"
    And the current account has 1 global "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin generates a token for the global license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 global "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin generates a token for the global license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 global "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for the global license (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 isolated "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for an isolated license (from a shared environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 shared "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for a shared license (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 isolated "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a token for a shared license (from the global environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And the current account has 1 global "license"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment generates a token for an isolated license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "name": "Isolated Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      { "name": "Isolated Token" }
      """
    And the response body should be a "token" with the following relationships:
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
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Environment generates a token for a shared license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "name": "Isolated Token"
          }
        }
      }
      """
    Then the response status should be "404"

  @ee
  Scenario: Environment generates a token for a global license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "name": "Isolated Token"
          }
        }
      }
      """
    Then the response status should be "404"

  @ee
  Scenario: Environment generates a token for an isolated license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "name": "Shared Token"
          }
        }
      }
      """
    Then the response status should be "404"

  @ee
  Scenario: Environment generates a token for a shared license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "name": "Shared Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      { "name": "Shared Token" }
      """
    And the response body should be a "token" with the following relationships:
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

  @ee
  Scenario: Environment generates a token for a global license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "name": "Shared Token"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "token" with the following attributes:
      """
      { "name": "Shared Token" }
      """
    And the response body should be a "token" with the following relationships:
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

  @ee
  Scenario: Product generates a license token with custom permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.read",
              "license.validate"
            ]
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
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ee
  Scenario: Product generates a license token with custom permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": [
              "license.read",
              "license.validate"
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
          "license.validate"
        ]
      }
      """

  @ee
  Scenario: Product generates a license token with permissions that exceed the license's permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And the response body should be an array of 1 error
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
  Scenario: Product generates a license token with permissions that exceed the license's permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses/$0/tokens" with the following:
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

  @ee
  Scenario: Product generates a license token with unsupported permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["license.create"]
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
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ee
  Scenario: Product generates a license token with unsupported permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["license.create"]
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

  @ee
  Scenario: Product generates a license token with invalid permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And the response body should be an array of 1 error
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
  Scenario: Product generates a license token with invalid permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses/$0/tokens" with the following:
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

  @ee
  Scenario: Product generates a license token with permissions for a license with wildcard permission (standard tier)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "permissions": ["*"] }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
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
    And the response body should be an array of 1 error
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
  Scenario: Product generates a license token with permissions for a license with wildcard permission (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "permissions": ["*"] }
      """
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses/$0/tokens" with the following:
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
    And the response body should be a "token" with the following attributes:
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

  Scenario: Product attempts to generate a token for a license it doesn't own
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/tokens"
    Then the response status should be "404"

  Scenario: User attempts to generate a token for their license (license owner)
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: User attempts to generate a token for their license (license user)
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And I am a user of account "test1"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: User attempts to generate a token for another license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "404"

  Scenario: Admin attempts to generate a license token for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test2/licenses/$0/tokens"
    Then the response status should be "401"

  Scenario: Admin requests tokens for one of their licenses
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 5 "licenses"
    And the current account has 1 "token" for each "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the response body should be an array of 1 "token"

  Scenario: Product requests a license's tokens
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the current account has 1 "token" for each "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the response body should be an array of 1 "token"

  Scenario: Product requests a license's token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the current account has 2 "tokens" for each "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens/$1"
    Then the response status should be "200"
    And the response body should be a "token"

  Scenario: Product attempts to request tokens for a license it doesn't own
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1/tokens"
    Then the response status should be "404"

  Scenario: License requests their tokens
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: License requests another license's tokens
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1/tokens"
    Then the response status should be "404"

  Scenario: User requests all tokens for their license (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    And the current user has 3 "licenses" as "owner"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: User requests all tokens for their license (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: User requests all tokens for another user's license
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "404"
