@api/v1
Feature: Show metric

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves a metric for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "200"
    And the JSON response should be a "metric"

  Scenario: Admin retrieves an invalid metric for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/invalid"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a metric for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
