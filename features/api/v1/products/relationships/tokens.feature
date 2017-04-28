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
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a nil expiry

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
    And the current account has 5 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests their tokens
    Given the current account is "test1"
    And the current account has 5 "products"
    And I am a product of account "test1"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests tokens for another product
    Given the current account is "test1"
    And the current account has 5 "products"
    And I am a product of account "test1"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$2/tokens"
    Then the response status should be "403"

  Scenario: User requests tokens for a product
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 6 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/tokens"
    Then the response status should be "403"
