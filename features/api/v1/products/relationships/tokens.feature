@api/v1
Feature: Generate authentication token for product

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
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "product-token",
        "expiry": null
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a product token with custom permissions
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
    And the JSON response should be a "token" with the following attributes:
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

  Scenario: Admin generates a product token with permissions that exceed the product's permissions
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

  Scenario: Admin generates a product token with unsupported permissions
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

  Scenario: Admin generates a product token with invalid permissions
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
    Then the response status should be "403"

  Scenario: User attempts to generate a product token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "403"

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
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests their tokens
    Given the current account is "test1"
    And the current account has 5 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And the current account has 1 "token" for each "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests tokens for another product
    Given the current account is "test1"
    And the current account has 5 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And the current account has 1 "token" for each "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$2/tokens"
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
    Then the response status should be "403"
