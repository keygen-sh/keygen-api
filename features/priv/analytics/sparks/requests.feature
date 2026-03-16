@ee @clickhouse
@api/priv
Feature: Request spark analytics
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
    When I send a GET request to "/accounts/test1/analytics/sparks/requests"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves request spark series for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "request_spark" rows:
      | status | count | created_date | created_at           |
      | 200    | 10    | 2100-08-23   | 2100-08-23T00:00:00Z |
      | 201    | 2     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | 404    | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | 200    | 8     | 2100-08-24   | 2100-08-24T00:00:00Z |
      | 301    | 1     | 2100-08-24   | 2100-08-24T00:00:00Z |
      | 500    | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/requests?date[start]=2100-08-23&date[end]=2100-08-24"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "requests.2xx", "date": "2100-08-23", "count": 12 },
          { "metric": "requests.2xx", "date": "2100-08-24", "count": 8 },
          { "metric": "requests.3xx", "date": "2100-08-24", "count": 1 },
          { "metric": "requests.4xx", "date": "2100-08-23", "count": 3 },
          { "metric": "requests.5xx", "date": "2100-08-24", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves request spark series with no data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/requests"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": []
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves request spark series with start date too old
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/requests?date[start]=2020-01-01&date[end]=2024-01-15"
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be greater than or equal to 2023-01-15",
        "source": {
          "parameter": "date[start]"
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves request spark series with end date in future
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/requests?date[start]=2024-01-01&date[end]=2099-01-01"
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be less than or equal to 2024-01-15",
        "source": {
          "parameter": "date[end]"
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And time is unfrozen

  Scenario: Product attempts to retrieve request spark series for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/requests"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve request spark series for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/requests"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve request spark series for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/requests"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
