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
    When I send a GET request to "/accounts/test1/analytics/events/license.validation.succeeded"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  # NB(ezekg) using future dates to avoid column-level TTL expiration during OPTIMIZE
  #           TABLE FINAL in tests, so dates MUST stay within clickhouse's Date type
  #           range (otherwise it overflows after 2149-06-06).
  Scenario: Admin retrieves event count for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "event_log" rows:
      | id                                   | event                        | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | license.validation.succeeded | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | license.validation.succeeded | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | license.validation.succeeded | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | license.validation.failed    | 2100-08-24T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | license.validation.succeeded | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/events/license.validation.succeeded?start_date=2100-08-20&end_date=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          {
            "event": "license.validation.succeeded",
            "count": 3
          }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves event count with wildcard event
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "event_log" rows:
      | id                                   | event                        | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | license.validation.succeeded | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | license.validation.succeeded | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | license.validation.succeeded | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | license.validation.failed    | 2100-08-24T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | license.validation.succeeded | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/events/license.validation.*?start_date=2100-08-20&end_date=2100-08-27"
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
    And time is unfrozen

  Scenario: Admin retrieves event count for license.created
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "event_log" rows:
      | id                                   | event           | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | license.created | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | license.created | 2100-08-24T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | license.created | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/events/license.created?start_date=2100-08-20&end_date=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          {
            "event": "license.created",
            "count": 2
          }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And time is unfrozen

  Scenario: Product attempts to retrieve event count for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/events/license.validation.succeeded"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve event count for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/events/license.validation.succeeded"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
