@api/v1
Feature: List authentication tokens

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
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "403"

  Scenario: Admin requests all tokens while authenticated
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 5 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "200"
    # NOTE(ezekg) 1 admin token, 3 product tokens, 5 user tokens
    And the JSON response should be an array of 9 "tokens"

  Scenario: Admin requests all tokens for a specific user
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 5 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=user&bearer[id]=$users[3]"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 5 "products"
    And I am a product of account "test1"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: User requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 6 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: User requests their tokens without authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "401"
