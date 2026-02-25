@ee @clickhouse
@api/priv
Feature: Spark series analytics
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
    When I send a GET request to "/accounts/test1/analytics/sparks/licenses"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves licenses spark series for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "license_spark" rows:
      | count | created_date |
      | 10    | 2100-08-23   |
      | 12    | 2100-08-24   |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/licenses?date[start]=2100-08-23&date[end]=2100-08-24"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "licenses", "date": "2100-08-23", "count": 10 },
          { "metric": "licenses", "date": "2100-08-24", "count": 12 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves machines spark series for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "machine_spark" rows:
      | count | created_date |
      | 5     | 2100-08-23   |
      | 6     | 2100-08-24   |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/machines?date[start]=2100-08-23&date[end]=2100-08-24"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "machines", "date": "2100-08-23", "count": 5 },
          { "metric": "machines", "date": "2100-08-24", "count": 6 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves invalid spark series
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/invalid"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Product attempts to retrieve spark series for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/licenses"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve spark series for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/licenses"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve spark series for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/licenses"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
