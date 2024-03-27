@api/v1
Feature: Show product

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
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a product for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Developer retrieves a product for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Sales retrieves a product for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Support retrieves a product for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Read-only retrieves a product for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Admin retrieves an invalid product for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested product 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve a product for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Environment retrieves an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "product"

  @ee
  Scenario: Environment retrieves a shared product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "product"

  @ee
  Scenario: Environment retrieves a global product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Product retrieves itself
    Given the current account is "test1"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Product attempts to retrieve another product
    Given the current account is "test1"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1"
    Then the response status should be "404"

  Scenario: License attempts to retrieve their product (default permissions)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their product (explicit permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["product.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their product (no permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve a product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1"
    Then the response status should be "404"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their product (default permissions)
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies" for each "product"
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "user"
    And the first "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

   Scenario: User attempts to retrieve their product (explicit permission)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["product.read"] }
      """
    And the first "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the response body should be a "product"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their product (no permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And the first "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve a product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job
