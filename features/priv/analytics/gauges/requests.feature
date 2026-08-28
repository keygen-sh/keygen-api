@ee @clickhouse
@api/priv
Feature: Request gauge analytics
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
    When I send a GET request to "/accounts/test1/analytics/gauges/requests"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves requests gauge for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "request_log" rows:
      | id                                   | status |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | 200    |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | 200    |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 201    |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | 301    |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | 404    |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 404    |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | 500    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/requests"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "requests.2xx", "count": 3 },
          { "metric": "requests.3xx", "count": 1 },
          { "metric": "requests.4xx", "count": 2 },
          { "metric": "requests.5xx", "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves requests gauge with no data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/requests"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "requests.2xx", "count": 0 },
          { "metric": "requests.3xx", "count": 0 },
          { "metric": "requests.4xx", "count": 0 },
          { "metric": "requests.5xx", "count": 0 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Product attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/requests"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/requests"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/requests"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
