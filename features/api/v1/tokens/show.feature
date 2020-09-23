@api/v1
Feature: Show authentication token

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should not be "403"

  Scenario: Admin requests a token while authenticated
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token" without a token

  Scenario: Admin retrieves an invalid token while authenticated
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested token 'invalid' was not found"
      }
      """

  Scenario: Product requests a token while authenticated
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User requests a token while authenticated
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User requests a token without authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "401"
