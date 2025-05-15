@api/v1
Feature: Create entitlements

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/entitlements"
    Then the response status should be "403"

  Scenario: Admin creates an entitlement for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Test Entitlement",
            "code": "TEST_ENTITLEMENT",
            "metadata": {
              "foo": "bar"
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Test Entitlement",
        "code": "TEST_ENTITLEMENT",
        "metadata": {
          "foo": "bar"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an incomplete entitlement for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "V1 Updates"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an entitlement for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Cool Feature",
            "code": "COOL_FEATURE"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Cool Feature",
            "code": "COOL_FEATURE"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Sales Feature",
            "code": "SALES_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Support Feature",
            "code": "SUPPORT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for an isolated environment (from isolated environment, implicit)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Isolated Entitlement",
            "code": "ISOLATED_ENTITLEMENT"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Isolated Entitlement",
        "code": "ISOLATED_ENTITLEMENT"
      }
      """
    And the response body should be an "entitlement" with the following relationships:
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
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for an isolated environment (from isolated environment, explicit)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Isolated Entitlement",
            "code": "ISOLATED_ENTITLEMENT"
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Isolated Entitlement",
        "code": "ISOLATED_ENTITLEMENT"
      }
      """
    And the response body should be an "entitlement" with the following relationships:
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
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for a shared environment (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Shared Entitlement",
            "code": "SHARED_ENTITLEMENT"
          },
          "relationships": {
            "environment": {
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
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for the nil environment (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Global Entitlement",
            "code": "GLOBAL_ENTITLEMENT"
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
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for an isolated environment (from shared environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Isolated Entitlement",
            "code": "ISOLATED_ENTITLEMENT"
          },
          "relationships": {
            "environment": {
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
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for a shared environment (in shared environment, implicit)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Shared Entitlement",
            "code": "SHARED_ENTITLEMENT"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Shared Entitlement",
        "code": "SHARED_ENTITLEMENT"
      }
      """
    And the response body should be an "entitlement" with the following relationships:
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

  @ee
  Scenario: Admin creates an entitlement for a shared environment (in shared environment, explicit)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Shared Entitlement",
            "code": "SHARED_ENTITLEMENT"
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Shared Entitlement",
        "code": "SHARED_ENTITLEMENT"
      }
      """
    And the response body should be an "entitlement" with the following relationships:
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

  @ee
  Scenario: Admin creates an entitlement for the nil environment (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Global Entitlement",
            "code": "GLOBAL_ENTITLEMENT"
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
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for an isolated environment (from nil environment)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 isolated "environment"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Isolated Entitlement",
            "code": "ISOLATED_ENTITLEMENT"
          },
          "relationships": {
            "environment": {
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
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for a shared environment (in nil environment)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 shared "environment"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Shared Entitlement",
            "code": "SHARED_ENTITLEMENT"
          },
          "relationships": {
            "environment": {
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
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an entitlement for the nil environment (in nil environment)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 isolated "environment"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Global Entitlement",
            "code": "GLOBAL_ENTITLEMENT"
          },
          "relationships": {
            "environment": {
              "data": null
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Global Entitlement",
        "code": "GLOBAL_ENTITLEMENT"
      }
      """
    And the response body should be an "entitlement" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an entitlement (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Isolated Feature",
            "code": "ISOLATED_FEATURE"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Isolated Feature",
        "code": "ISOLATED_FEATURE"
      }
      """
    And the response body should be an "entitlement" with the following relationships:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an entitlement (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Shared Feature",
            "code": "SHARED_FEATURE"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "name": "Shared Feature",
        "code": "SHARED_FEATURE"
      }
      """
    And the response body should be an "entitlement" with the following relationships:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an entitlement (global)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Global Feature",
            "code": "GLOBAL_FEATURE"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Product Feature",
            "code": "PRODUCT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Product Feature",
            "code": "PRODUCT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Product Feature",
            "code": "PRODUCT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Product Feature",
            "code": "PRODUCT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # product-specific webhook smoke tests
  Scenario: Admin creates an entitlement and generates authorized webhooks
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "webhook-endpoints" for each "product"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I authenticate with a token
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Product Feature",
            "code": "PRODUCT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 5 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
