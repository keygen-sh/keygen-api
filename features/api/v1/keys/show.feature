@api/v1
Feature: Show key

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
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a key for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "200"
    And the JSON response should be a "key"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves an invalid key for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/invalid"
    Then the response status should be "404"

  Scenario: Product retrieves a key for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "key"
    And the current product has 1 "key"
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "200"
    And the JSON response should be a "key"

  Scenario: Product attempts to retrieve a key for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "key"
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a key for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
