@api/v1
Feature: List products

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
    And the current account has 2 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"

  Scenario: Admin retrieves all products for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 3 "products"

  Scenario: Developer retrieves all products for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 2 "products"

  Scenario: Sales retrieves all products for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 2 "products"

  Scenario: Support retrieves all products for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 5 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 5 "products"

  Scenario: Read-only retrieves all products for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 5 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 5 "products"

  Scenario: Admin retrieves a paginated list of products
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "products"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/products?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/products?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/products?page[number]=4&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """

  Scenario: Admin retrieves a paginated list of products with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of products with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of products with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all products without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 10 "products"

  Scenario: Admin retrieves all products with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "products"

  Scenario: Admin retrieves all products with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "products"

  Scenario: Admin retrieves all products with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all products with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all products for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Environment retrieves all isolated products
    Given the current account is "test1"
    And the current account has 3 isolated "products"
    And the current account has 3 shared "products"
    And the current account has 3 global "products"
    And I am the first environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "products"
    And the response body should be an array of 3 "products" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves all shared products
    Given the current account is "test1"
    And the current account has 3 isolated "products"
    And the current account has 3 shared "products"
    And the current account has 3 global "products"
    And I am the second environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "products"
    And the response body should be an array of 3 "products" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[1]" },
          "data": { "type": "environments", "id": "$environments[1]" }
        }
      }
      """
    And the response body should be an array of 3 "products" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """

  Scenario: Product attempts to retrieve all products
    Given the current account is "test1"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their products (default permissions)
    Given the current account is "test1"
    And the current account has 1 licensed "product"
    And the current account has 1 closed "product"
    And the current account has 1 open "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "product"
    And I am the first license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their products (explicit permission)
    Given the current account is "test1"
    And the current account has 1 licensed "product"
    And the current account has 1 closed "product"
    And the current account has 1 open "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "product" with the following:
      """
      { "permissions": ["product.read"] }
      """
    And I am the first license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 2 "products"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their products (no permission)
    Given the current account is "test1"
    And the current account has 1 licensed "product"
    And the current account has 1 closed "product"
    And the current account has 1 open "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "product" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I am the first license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve all products
    Given the current account is "test1"
    And the current account has 5 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their products (default permissions)
    Given the current account is "test1"
    And the current account has 2 licensed "products"
    And the current account has 1 closed "product"
    And the current account has 1 open "product"
    And the current account has 1 "policy" for each "product"
    And the current account has 1 "license" for each "policy"
    And the current account has 1 "user"
    And the first "license" belongs to the last "user"
    And the second "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

   Scenario: User attempts to retrieve their products (explicit permission)
    Given the current account is "test1"
    And the current account has 2 licensed "products"
    And the current account has 1 closed "product"
    And the current account has 1 open "product"
    And the current account has 1 "policy" for each "product"
    And the current account has 1 "license" for each "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["product.read"] }
      """
    And the first "license" belongs to the last "user"
    And the second "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "200"
    And the response body should be an array with 3 "products"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their products (no permission)
    Given the current account is "test1"
    And the current account has 2 licensed "products"
    And the current account has 1 closed "product"
    And the current account has 1 open "product"
    And the current account has 1 "policy" for each "product"
    And the current account has 1 "license" for each "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And the first "license" belongs to the last "user"
    And the second "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve all products
    Given the current account is "test1"
    And the current account has 5 "products"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job
