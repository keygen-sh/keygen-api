@api/v1
Feature: Show request logs

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
    And the current account has 1 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a log for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/$0"
    Then the response status should be "200"
    And the JSON response should be a "request-log"

  Scenario: Admin retrieves an invalid log for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested request log 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve a log for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
