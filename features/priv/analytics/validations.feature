@ee @clickhouse
@api/priv
Feature: Validation series analytics
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
    When I send a GET request to "/accounts/test1/analytics/validations"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves validation series for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "license" rows:
      | id                                   | name      |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | License 1 |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | License 2 |
    And the current account has the following "license_validation_spark" rows:
      | license_id                           | validation_code | count | created_date | created_at           |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | VALID           | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | VALID           | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | EXPIRED         | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | NO_MACHINE      | 4     | 2100-08-24   | 2100-08-24T00:00:00Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations?date[start]=2100-08-20&date[end]=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "date": "2100-08-24", "count": 2 },
          { "metric": "validations.no-machine", "date": "2100-08-24", "count": 4 },
          { "metric": "validations.valid", "date": "2100-08-23", "count": 8 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves validation series filtered by license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "license" rows:
      | id                                   | name      |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | License 1 |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | License 2 |
    And the current account has the following "license_validation_spark" rows:
      | license_id                           | validation_code | count | created_date | created_at           |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | VALID           | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | VALID           | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | EXPIRED         | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations?license=bf9b523f-dd65-48a2-9512-fb66ba6c3714&date[start]=2100-08-20&date[end]=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "date": "2100-08-24", "count": 2 },
          { "metric": "validations.valid", "date": "2100-08-23", "count": 5 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves validation series with no data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": []
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves validation series with start date too old
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations?date[start]=2020-01-01&date[end]=2024-01-15"
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

  Scenario: Admin retrieves validation series with end date in future
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations?date[start]=2024-01-01&date[end]=2099-01-01"
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

  Scenario: Product attempts to retrieve validation series for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve validation series for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve validation series for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
