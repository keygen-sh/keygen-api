@api/v1
Feature: User password

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: User resets their password
    Given the current account is "test1"
    And the current account has 3 "users"
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      { "email": "$users[1].email" }
      """
    Then the response status should be "204"

  Scenario: User resets their password using a bad email
    Given the current account is "test1"
    And the current account has 3 "users"
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      { "email": "bad@email.com" }
      """
    Then the response status should be "204"
