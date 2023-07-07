@api/v1
Feature: Create product
  Background:
    Given the following "plan" rows exist:
      | id                                   | name  |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Std 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1 |
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
    When I send a POST request to "/accounts/test1/products"
    Then the response status should be "403"

  Scenario: Admin creates a product for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 4 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "code": "cool",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with a LICENSED distribution strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "distributionStrategy": "LICENSED"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "product" with the distributionStrategy "LICENSED"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with a OPEN distribution strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "distributionStrategy": "OPEN"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "product" with the distributionStrategy "OPEN"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with a CLOSED distribution strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "distributionStrategy": "CLOSED"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "product" with the distributionStrategy "CLOSED"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with an invalid URL for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 4 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "file:///boom.sh",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an incomplete product for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a product for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a product for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And I am the last environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Isolated Product"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "product" with the following relationships:
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
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a shared product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And I am the last environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Shared Product"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "product" with the following relationships:
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
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Hello World App",
            "platforms": ["PC"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin creates a product with custom permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "license.create",
              "license.validate",
              "license.read"
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

  @ce
  Scenario: Admin creates a product with custom permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "license.create",
              "license.validate",
              "license.read"
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
  Scenario: Admin creates a product with custom permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "license.create",
              "license.validate",
              "license.read"
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
  Scenario: Admin creates a product with custom permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "license.create",
              "license.validate",
              "license.read"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "product"
    And the response body should be a "product" with the following attributes:
      """
      {
        "permissions": [
          "license.create",
          "license.read",
          "license.validate"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a product with unsupported permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "product.create"
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
  Scenario: Admin creates a product with unsupported permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "product.create"
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
          "about": "https://keygen.sh/docs/api/products/#products-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a product with invalid permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "foo.bar"
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
  Scenario: Admin creates a product with invalid permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Micro-service",
            "permissions": [
              "foo.bar"
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
          "about": "https://keygen.sh/docs/api/products/#products-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
