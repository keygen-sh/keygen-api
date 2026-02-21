@ee @clickhouse
@api/priv
Feature: Usage analytics
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
    When I send a GET request to "/accounts/test1/analytics/usage"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  # NB(ezekg) using future dates to avoid column-level TTL expiration during OPTIMIZE
  #           TABLE FINAL in tests, so dates MUST stay within clickhouse's Date type
  #           range (otherwise it overflows after 2149-06-06).
  Scenario: Admin retrieves usage counts for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "request_log" rows:
      | id                                   | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | 2100-08-24T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 2100-08-24T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | 2100-08-25T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/usage?date[start]=2100-08-23&date[end]=2100-08-25"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "requests", "date": "2100-08-23", "count": 2 },
          { "metric": "requests", "date": "2100-08-24", "count": 3 },
          { "metric": "requests", "date": "2100-08-25", "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves usage counts with no data for some days
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "request_log" rows:
      | id                                   | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | 2100-08-25T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/usage?date[start]=2100-08-23&date[end]=2100-08-25"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "requests", "date": "2100-08-23", "count": 1 },
          { "metric": "requests", "date": "2100-08-24", "count": 0 },
          { "metric": "requests", "date": "2100-08-25", "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves usage counts with start date too old
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/usage?date[start]=2020-01-01&date[end]=2024-01-15"
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

  Scenario: Admin retrieves usage counts with end date in future
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/usage?date[start]=2024-01-01&date[end]=2099-01-01"
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

  Scenario: Product attempts to retrieve usage counts for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/usage"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve usage counts for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/usage"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
