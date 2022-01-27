@api/v1
Feature: Token expiration

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin attempts to use an expired token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an expired authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "Token is expired",
        "code": "TOKEN_EXPIRED"
      }
      """

  Scenario: User attempts to use an expired token
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an expired authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"

  Scenario: Product attempts to use an expired token
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an expired authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
