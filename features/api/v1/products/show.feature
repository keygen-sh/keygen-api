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
    And the JSON response should be a "product"

  Scenario: Admin retrieves a product for their account with correct relationship data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 2 "users"
    And the current account has 31 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]", "userId": "$users[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the JSON response should be a "product" with the following relationships:
      """
      {
        "policies": {
          "links": { "related": "/v1/accounts/$accounts[0]/products/$products[0]/policies" },
          "meta": { "count": 1 }
        },
        "licenses": {
          "links": { "related": "/v1/accounts/$accounts[0]/products/$products[0]/licenses" },
          "meta": { "count": 31 }
        },
        "users": {
          "links": { "related": "/v1/accounts/$accounts[0]/products/$products[0]/users" },
          "meta": { "count": 1 }
        }
      }
      """

  Scenario: Admin retrieves an invalid product for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/invalid"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a product for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "products"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: Product retrieves itself
    Given the current account is "test1"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0"
    Then the response status should be "200"
    And the JSON response should be a "product"

  Scenario: Product attempts to retrieve another product
    Given the current account is "test1"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1"
    Then the response status should be "403"
