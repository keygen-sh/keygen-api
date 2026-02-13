@ee @clickhouse
@api/priv
Feature: Event analytics
  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/-/accounts/test1/analytics/events/license.validation.succeeded"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves event count for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/-/accounts/test1/analytics/events/license.validation.succeeded?start_date=2024-01-01&end_date=2024-01-07"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          {
            "event": "license.validation.succeeded",
            "count": 0
          }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves event count with wildcard event
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/-/accounts/test1/analytics/events/license.validation.*?start_date=2024-01-01&end_date=2024-01-07"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          {
            "event": "license.validation.failed",
            "count": 1
          },
          {
            "event": "license.validation.succeeded",
            "count": 3
          }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves event count for license.created
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/-/accounts/test1/analytics/events/license.created?start_date=2024-01-01&end_date=2024-01-07"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          {
            "event": "license.created",
            "count": 0
          }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to retrieve event count for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/-/accounts/test1/analytics/events/license.validation.succeeded"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve event count for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/-/accounts/test1/analytics/events/license.validation.succeeded"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
