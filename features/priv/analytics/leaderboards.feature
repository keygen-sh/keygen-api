@ee @clickhouse
@api/priv
Feature: Leaderboard analytics
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
    When I send a GET request to "/accounts/test1/analytics/leaderboards/ips"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  # NOTE(ezekg) Using future dates (2100) to avoid column-level TTL expiration
  #             during OPTIMIZE TABLE FINAL in tests. Must stay within ClickHouse's
  #             Date type range (max 2149-06-06).
  Scenario: Admin retrieves IPs leaderboard
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "request_log" rows:
      | id                                   | ip             | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | 192.168.1.1    | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | 192.168.1.1    | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 192.168.1.1    | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | 10.0.0.1       | 2100-08-24T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 10.0.0.1       | 2100-08-25T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | 172.16.0.1     | 2100-08-25T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | 192.168.1.1    | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/ips?start_date=2100-08-20&end_date=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "identifier": "192.168.1.1", "count": 3 },
          { "identifier": "10.0.0.1", "count": 2 },
          { "identifier": "172.16.0.1", "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves URLs leaderboard
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "request_log" rows:
      | id                                   | method | url                               | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | POST   | /v1/licenses/foo/actions/validate | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | POST   | /v1/licenses/foo/actions/validate | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | POST   | /v1/licenses/bar/actions/validate | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | GET    | /v1/licenses                      | 2100-08-24T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | GET    | /v1/licenses                      | 2100-08-25T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | POST   | /v1/machines                      | 2100-08-25T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | POST   | /v1/licenses/foo/actions/validate | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/urls?start_date=2100-08-20&end_date=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
        {
          "data": [
            { "identifier": "GET /v1/licenses", "count": 2 },
            { "identifier": "POST /v1/licenses/foo/actions/validate", "count": 2 },
            { "identifier": "POST /v1/machines", "count": 1 },
            { "identifier": "POST /v1/licenses/bar/actions/validate", "count": 1 }
          ]
        }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves licenses leaderboard
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "license" rows:
      | id                                   | name      |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | License 1 |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | License 2 |
      | 7559899f-2761-4b9c-a43e-2d919efa9b04 | License 3 |
    And the current account has the following "request_log" rows:
      | id                                   | resource_type | resource_id                          | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | License       | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | License       | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | License       | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | License       | a499bb93-9902-4b52-8a04-76944ad7f660 | 2100-08-24T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | License       | a499bb93-9902-4b52-8a04-76944ad7f660 | 2100-08-25T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | License       | 7559899f-2761-4b9c-a43e-2d919efa9b04 | 2100-08-25T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | License       | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/licenses?start_date=2100-08-20&end_date=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "identifier": "bf9b523f-dd65-48a2-9512-fb66ba6c3714", "count": 3 },
          { "identifier": "a499bb93-9902-4b52-8a04-76944ad7f660", "count": 2 },
          { "identifier": "7559899f-2761-4b9c-a43e-2d919efa9b04", "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves user-agents leaderboard
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "request_log" rows:
      | id                                   | user_agent   | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | keygen/1.0.0 | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | keygen/1.0.0 | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | keygen/1.0.0 | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | curl/8.1.2   | 2100-08-24T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | curl/8.1.2   | 2100-08-25T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | Mozilla/5.0  | 2100-08-25T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | keygen/1.0.0 | 2099-08-20T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/user-agents?start_date=2100-08-20&end_date=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "identifier": "keygen/1.0.0", "count": 3 },
          { "identifier": "curl/8.1.2", "count": 2 },
          { "identifier": "Mozilla/5.0", "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves leaderboard with limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "request_log" rows:
      | id                                   | ip          | created_at               |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | 192.168.1.1 | 2100-08-23T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | 192.168.1.1 | 2100-08-23T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 192.168.1.1 | 2100-08-24T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | 10.0.0.1    | 2100-08-24T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 10.0.0.1    | 2100-08-25T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | 172.16.0.1  | 2100-08-25T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/ips?start_date=2100-08-20&end_date=2100-08-27&limit=2"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "identifier": "192.168.1.1", "count": 3 },
          { "identifier": "10.0.0.1", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves invalid leaderboard type
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/invalid"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Product attempts to retrieve leaderboard for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/ips"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve leaderboard for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/leaderboards/ips"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve leaderboard for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/analytics/leaderboards/ips"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
