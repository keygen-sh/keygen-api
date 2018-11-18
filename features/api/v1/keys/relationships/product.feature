@api/v1
Feature: Key product relationship

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
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0/product"
    Then the response status should be "403"

  Scenario: Admin retrieves the product for a key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0/product"
    Then the response status should be "200"
    And the JSON response should be a "product"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "request-log" job

  Scenario: Product retrieves the product for a key
    Given the current account is "test1"
    And the current account has 3 "keys"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0/product"
    Then the response status should be "200"
    And the JSON response should be a "product"
    And sidekiq should have 1 "request-log" job

  Scenario: Product retrieves the product for a key of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 3 "keys"
    And all "keys" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0/product"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve the product for a key
    Given the current account is "test1"
    And the current account has 3 "keys"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0/product"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to retrieve the product for a key of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0/product"
    Then the response status should be "401"
    And sidekiq should have 1 "request-log" job
