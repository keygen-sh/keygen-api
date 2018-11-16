@api/v1
Feature: Metric counts

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
    And the current account has 2 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "403"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves metric counts for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 52 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "200"
    And the JSON response should contain meta with the following:
      """
      {
        "$date.format": 52
      }
      """
      And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves metric counts for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 52 "metrics"
    And the first 19 "metrics" have the following attributes:
      """
      {
        "metric": "license.validation.succeeded"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/actions/count?metrics[]=license.validation.succeeded"
    Then the response status should be "200"
    And the JSON response should contain meta with the following:
      """
      {
        "$date.format": 19
      }
      """
      And sidekiq should have 0 "log" jobs

  Scenario: User attempts to retrieve metric counts for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "metrics"
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And sidekiq should have 0 "log" jobs