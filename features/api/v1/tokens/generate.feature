@api/v1
Feature: Generate authentication token
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

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should not be "403"

  Scenario: Admin generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following relationships:
      """
      {
        "bearer": {
          "links": { "related": "/v1/accounts/$account/users/$users[0]" },
          "data": { "type": "users", "id": "$users[0]" }
        }
      }
      """
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "admin-token",
        "expiry": null
      }
      """
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a new token via token authentication
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following relationships:
      """
      {
        "bearer": {
          "links": { "related": "/v1/accounts/$account/users/$users[0]" },
          "data": { "type": "users", "id": "$users[0]" }
        }
      }
      """
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "admin-token",
        "expiry": null
      }
      """
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a named token
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following attributes:
      """
      { "name": "Client Token" }
      """
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates an environment token
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "environment"
    And I am an admin of account "test1"
    And I use an authentication token
    And time is frozen at "2023-03-24T00:00:00.000Z"
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Environment Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "environments",
                "id": "$environments[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin generates a product token
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    And time is frozen at "2023-03-24T00:00:00.000Z"
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Product Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin generates a license token
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And time is frozen at "2023-03-24T00:00:00.000Z"
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "License Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin generates a user token
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    And time is frozen at "2023-03-24T00:00:00.000Z"
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "User Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "user",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following relationships:
      """
      {
        "bearer": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "name": "User Token",
        "expiry": "2023-04-07T00:00:00.000Z"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin generates a user token without an expiry
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "User Token",
            "expiry": null
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "user",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following relationships:
      """
      {
        "bearer": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "name": "User Token",
        "expiry": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a token without a bearer
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Token"
          },
          "relationships": {
            "bearer": {
              "data": null
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
        "detail": "cannot be null",
        "source": {
          "pointer": "/data/relationships/bearer/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Global admin generates a token for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[-1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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

  @ee
  Scenario: Isolated admin generates a token for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[-1].email:password\"",
        "Keygen-Environment": "isolated"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin generates a token for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[-1].email:password\"",
        "Keygen-Environment": "isolated"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Global admin generates a token for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[-1].email:password\"",
        "Keygen-Environment": "isolated"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Shared admin generates a token for an shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[-1].email:password\"",
        "Keygen-Environment": "shared"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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

  @ee
  Scenario: Isolated admin generates a token for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[-1].email:password\"",
        "Keygen-Environment": "shared"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Global admin generates a token for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[-1].email:password\"",
        "Keygen-Environment": "shared"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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

  @ee
  Scenario: Global admin generates a token for the global environment
    Given the current account is "test1"
    And the current account has 1 global "admin"
    And I am the last admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[-1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    Then the response status should be "201"
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
  Scenario: Isolated admin generates a token for the global environment
    Given the current account is "test1"
    And the current account has 1 isolated "admin"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[-1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Shared admin generates a token for the global environment
    Given the current account is "test1"
    And the current account has 1 shared "admin"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[-1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Isolated admin generates a token for the global environment (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[1].email:password\"",
        "Keygen-Environment": "isolated"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Shared admin generates a token for an isolated environment (from a shared environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[2].email:password\"",
        "Keygen-Environment": "shared"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Isolated admin generates a token for a shared environment (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[1].email:password\"",
        "Keygen-Environment": "isolated"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
  Scenario: Global admin generates a token for a shared environment (from the global environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin generates a token for a global environment (from a shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[1].email:password\"",
        "Keygen-Environment": "shared"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin generates a token for a global environment (from an isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "admin"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[2].email:password\"",
        "Keygen-Environment": "isolated"
      }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin generates a new token with custom permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin generates a new token with custom permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "ent1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/ent1/tokens" with the following:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a new token with custom permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin generates a new token with custom permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "ent1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/ent1/tokens" with the following:
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
    Then the response status should be "201"
    And the response body should be a "token" with the following attributes:
      """
      {
        "permissions": ["license.validate"]
      }
      """
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin with 2FA enabled generates a new token via basic authentication without an OTP code
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
       "title": "Unauthorized",
        "detail": "second factor is required",
        "code": "OTP_REQUIRED",
        "source": {
          "pointer": "/meta/otp"
        }
      }
      """

  Scenario: Admin with 2FA enabled generates a new token via basic authentication with an invalid OTP code
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "meta": {
          "otp": "000000"
        }
      }
      """
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "second factor must be valid",
        "code": "OTP_INVALID",
        "source": {
          "pointer": "/meta/otp"
        }
      }
      """

  Scenario: Admin with 2FA enabled generates a new token via basic authentication with a valid OTP code
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "admin-token"
      }
      """

  Scenario: Developer generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "developer-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "sales-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Support generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "support-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "read-only-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a new token with a custom expiry via basic authentication
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2531-01-01T00:00:00.000Z"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with an expiry "2531-01-01T00:00:00.000Z"
    And the response body should be a "token" with the following attributes:
      """
      { "kind": "admin-token" }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with an expiry
    And the response body should be a "token" with the following attributes:
      """
      { "kind": "user-token" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token via token authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And time is frozen at "2023-03-24T00:00:00.000Z"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with an expiry
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "name": null,
        "expiry": "2023-04-07T00:00:00.000Z"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Developer generates a new token
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am the first developer of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Dev Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "user",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "token" without an expiry
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following relationships:
      """
      {
        "bearer": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """
    And the response body should be a "token" with the following attributes:
      """
      { "kind": "developer-token" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer generates a token for an admin
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am the first developer of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "Admin Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "user",
                "id": "$users[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (ensure the token or license is allowed to access all resources)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a token for another user
    Given the current account is "test1"
    And the current account has 2 "users"
    And I am the first user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "User Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "user",
                "id": "$users[2]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a token for an admin
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am the first user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "name": "User Token"
          },
          "relationships": {
            "bearer": {
              "data": {
                "type": "user",
                "id": "$users[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token with inherited permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["token.generate"] }
      """
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" without a "permissions" attribute
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User generates a new token with inherited permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["token.generate", "license.read", "license.validate"] }
      """
    And I am a user of account "ent1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/ent1/tokens"
    Then the response status should be "201"
    And the response body should be a "token" with the following attributes:
      """
      { "permissions": ["license.read", "license.validate", "token.generate"] }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without permission (standard tier)
    Given the current account is "test1"
    And the current account has 1 "user" with the following:
      """
      { "permissions": [] }
      """
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User attempts to generate a new token without permission (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "user" with the following:
      """
      { "permissions": [] }
      """
    And I am a user of account "ent1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/ent1/tokens"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: User attempts to generate a new token with custom permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["user.create"]
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: User attempts to generate a new token with custom permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 1 "user"
    And I am a user of account "ent1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/ent1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["user.create"]
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User generates a new token with allowed permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "ent1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/ent1/tokens" with the following:
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
    Then the response status should be "201"
    And the response body should be a "token" with the following attributes:
      """
      {
        "permissions": ["license.validate"]
      }
      """
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User generates a new token with disallowed permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "ent1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/ent1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "attributes": {
            "permissions": ["admin.create"]
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
        "detail": "unsupported permissions",
        "code": "PERMISSIONS_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token with a custom expiry via basic authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2049-01-01T00:00:00.000Z"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with an expiry "2049-01-01T00:00:00.000Z"
    And the response body should be a "token" with the following attributes:
      """
      { "kind": "user-token" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token without an expiry via basic authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    Then the response status should be "201"
    And the response body should be a "token" with a token
    And the response body should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token with an invalid email
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"foo@bar.example:secret\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email must be valid",
        "code": "EMAIL_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """

  Scenario: User attempts to generate a new token with an invalid email (v1.8)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"foo@bar.example:secret\"" }
      """
    And I use API version "1.8"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email must be valid",
        "code": "EMAIL_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.8" }
      """

  Scenario: User attempts to generate a new token with an invalid email (v1.7)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"foo@bar.example:secret\"" }
      """
    And I use API version "1.7"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email and password must be valid",
        "code": "CREDENTIALS_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.7" }
      """

  Scenario: User attempts to generate a new token with an invalid password
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:someBadPassword\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password must be valid",
        "code": "PASSWORD_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """

  Scenario: User attempts to generate a new token with an invalid password (v1.8)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:someBadPassword\"" }
      """
    And I use API version "1.8"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password must be valid",
        "code": "PASSWORD_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.8" }
      """

  Scenario: User attempts to generate a new token with an invalid password (v1.7)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:someBadPassword\"" }
      """
    And I use API version "1.7"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email and password must be valid",
        "code": "CREDENTIALS_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.7" }
      """

  Scenario: User attempts to generate a new token without authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"

  Scenario: User attempts to generate a new token while banned
    Given the current account is "test1"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2049-01-01T00:00:00.000Z"
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (user is banned)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without a password
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password is required",
        "code": "PASSWORD_REQUIRED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without a password (v1.8)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:\"" }
      """
    And I use API version "1.8"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password is required",
        "code": "PASSWORD_REQUIRED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.8" }
      """

  Scenario: User attempts to generate a new token without a password (v1.7)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:\"" }
      """
    And I use API version "1.7"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email and password must be valid",
        "code": "CREDENTIALS_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.7" }
      """

  Scenario: User attempts to generate a new token without a password (configured SSO, matched email, existing admin)
    Given the current account is "test1"
    And the current account has SSO configured for "keygen.example"
    And the current account has 1 "admin" with the following:
      """
      { "email": "zeke@keygen.example" }
      """
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"zeke@keygen.example:\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "single sign on is required",
        "code": "SSO_REQUIRED",
        "source": {
          "header": "Authorization"
        },
        "links": {
          "redirect": "https://api.workos.test/sso/authorize"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without a password (configured SSO, matched email, existing user)
    Given the current account is "test1"
    And the current account has SSO configured for "keygen.example"
    And the current account has 1 "user" with the following:
      """
      { "email": "zeke@keygen.example" }
      """
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"zeke@keygen.example:\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "single sign on is required",
        "code": "SSO_REQUIRED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without a password (configured SSO, matched email, new user)
    Given the current account is "test1"
    And the current account has SSO configured for "keygen.example"
    And I send the following headers:
      """
      { "Authorization": "Basic \"zeke@keygen.example:\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "single sign on is required",
        "code": "SSO_REQUIRED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without a password (configured SSO, mismatched email, existing admin)
    Given the current account is "test1"
    And the current account has SSO configured for "keygen.example"
    And the current account has 1 "admin" with the following:
      """
      { "email": "zeke@acme.example" }
      """
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"zeke@acme.example:\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "single sign on is required",
        "code": "SSO_REQUIRED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without a password (configured SSO, mismatched email, existing user)
    Given the current account is "test1"
    And the current account has SSO configured for "keygen.example"
    And the current account has 1 "user" with the following:
      """
      { "email": "zeke@acme.example" }
      """
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"zeke@acme.example:\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password is required",
        "code": "PASSWORD_REQUIRED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token without a password (configured SSO, mismatched email, new user)
    Given the current account is "test1"
    And the current account has SSO configured for "keygen.example"
    And I send the following headers:
      """
      { "Authorization": "Basic \"zeke@acme.example:\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email must be valid",
        "code": "EMAIL_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token for a passwordless user
    Given the current account is "test1"
    And the current account has 1 passwordless "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:secret\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password is unsupported",
        "code": "PASSWORD_NOT_SUPPORTED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token for a passwordless user (v1.8)
    Given the current account is "test1"
    And the current account has 1 passwordless "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:secret\"" }
      """
    And I use API version "1.8"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password is unsupported",
        "code": "PASSWORD_NOT_SUPPORTED",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.8" }
      """

  Scenario: User attempts to generate a new token for a passwordless user (v1.7)
    Given the current account is "test1"
    And the current account has 1 passwordless "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:secret\"" }
      """
    And I use API version "1.7"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email and password must be valid",
        "code": "CREDENTIALS_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.7" }
      """

   Scenario: Anonymous attempts to send a null byte within the email
    Given the current account is "test1"
    And the current account has 1 "user" with the following:
      """
      { "email": "foo@bar.example" }
      """
    And I send the following raw headers:
      """
      Authorization: Basic Zm9vQGJhAHIuZXhhbXBsZTpiYXo=
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "email is required",
        "code": "EMAIL_REQUIRED",
        "source": {
          "header": "Authorization"
        }
      }
      """

  Scenario: Anonymous attempts to send a null byte within the password
    Given the current account is "test1"
    And the current account has 1 "user" with the following:
      """
      { "email": "foo@bar.example" }
      """
    And I send the following raw headers:
      """
      Authorization: Basic Zm9vQGJhci5leGFtcGxlOmJhAHo=
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "password must be valid",
        "code": "PASSWORD_INVALID",
        "source": {
          "header": "Authorization"
        }
      }
      """

  Scenario: Anonymous attempts to send a badly encoded email address
    Given the current account is "test1"
    And I send the following badly encoded headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The request could not be completed because it contains an invalid byte sequence (check encoding)",
        "code": "ENCODING_INVALID"
      }
      """
