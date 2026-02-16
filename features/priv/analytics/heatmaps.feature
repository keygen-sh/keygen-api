@api/priv
Feature: Heatmaps analytics
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
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves expirations heatmap for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-03-01T00:00:00.000Z"
    And the current account has the following "license" rows:
      | id                                   | expiry                   |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | 2024-03-05T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | 2024-03-05T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 2024-03-10T00:00:00.000Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations?start_date=2024-03-01&end_date=2024-03-14"
    Then the response status should be "200"
    And the response body should be a "data" array with 14 items
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "date": "2024-03-01", "x": 0, "y": 5, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-02", "x": 0, "y": 6, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-03", "x": 1, "y": 0, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-04", "x": 1, "y": 1, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-05", "x": 1, "y": 2, "temperature": 1.0, "count": 2 },
          { "date": "2024-03-06", "x": 1, "y": 3, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-07", "x": 1, "y": 4, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-08", "x": 1, "y": 5, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-09", "x": 1, "y": 6, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-10", "x": 2, "y": 0, "temperature": 0.5, "count": 1 },
          { "date": "2024-03-11", "x": 2, "y": 1, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-12", "x": 2, "y": 2, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-13", "x": 2, "y": 3, "temperature": 0.0, "count": 0 },
          { "date": "2024-03-14", "x": 2, "y": 4, "temperature": 0.0, "count": 0 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves expirations heatmap with default date range
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations"
    Then the response status should be "200"
    And the response body should be a "data" array with 365 items
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves heatmap with end date too far in future
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations?end_date=2099-01-01"
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      { "title": "Bad request", "detail": "End date must be less than or equal to 2025-01-15", "source": { "parameter": "end_date" } }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves invalid heatmap type
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/heatmaps/invalid"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  @ee
  Scenario: Admin retrieves heatmap for an isolated environment
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name     |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   |
      | 0aef7c4a-953e-4824-9e16-9be2361afcf4 |                                      | Global   |
    And the current account has the following "policy" rows:
      | id                                   | environment_id                       | product_id                           | name     |
      | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Isolated |
      | e44ba43d-a052-4d4c-b039-8b46a05ca4be | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | fa48996c-9c98-41c1-a2c3-21de98aefafe | Shared   |
      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |                                      | 0aef7c4a-953e-4824-9e16-9be2361afcf4 | Global   |
    And the current account has the following "license" rows:
      | id                                   | environment_id                       | policy_id                            | expiry                   |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-05T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-05T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-05T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 07b5b667-9d09-4f0b-a433-9cfff4111b61 | 2026-03-09T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | e44ba43d-a052-4d4c-b039-8b46a05ca4be | 2026-03-10T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |                                      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 | 2026-03-10T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-10T00:00:00.000Z |
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations?start_date=2026-03-05&end_date=2026-03-10"
    Then the response status should be "200"
    And the response body should be a "data" array with 6 items
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "date": "2026-03-05", "x": 0, "y": 4, "temperature": 1.0, "count": 3 },
          { "date": "2026-03-06", "x": 0, "y": 5, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-07", "x": 0, "y": 6, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-08", "x": 1, "y": 0, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-09", "x": 1, "y": 1, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-10", "x": 1, "y": 2, "temperature": 0.3, "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  @ee
  Scenario: Admin retrieves heatmap for a shared environment
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name     |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   |
      | 0aef7c4a-953e-4824-9e16-9be2361afcf4 |                                      | Global   |
    And the current account has the following "policy" rows:
      | id                                   | environment_id                       | product_id                           | name     |
      | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Isolated |
      | e44ba43d-a052-4d4c-b039-8b46a05ca4be | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | fa48996c-9c98-41c1-a2c3-21de98aefafe | Shared   |
      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |                                      | 0aef7c4a-953e-4824-9e16-9be2361afcf4 | Global   |
    And the current account has the following "license" rows:
      | id                                   | environment_id                       | policy_id                            | expiry                   |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-05T00:00:00.000Z |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-05T00:00:00.000Z |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-05T00:00:00.000Z |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 07b5b667-9d09-4f0b-a433-9cfff4111b61 | 2026-03-09T00:00:00.000Z |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | e44ba43d-a052-4d4c-b039-8b46a05ca4be | 2026-03-10T00:00:00.000Z |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |                                      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 | 2026-03-10T00:00:00.000Z |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 | 2026-03-10T00:00:00.000Z |
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations?start_date=2026-03-05&end_date=2026-03-10"
    Then the response status should be "200"
    And the response body should be a "data" array with 6 items
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "date": "2026-03-05", "x": 0, "y": 4, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-06", "x": 0, "y": 5, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-07", "x": 0, "y": 6, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-08", "x": 1, "y": 0, "temperature": 0.0, "count": 0 },
          { "date": "2026-03-09", "x": 1, "y": 1, "temperature": 0.5, "count": 1 },
          { "date": "2026-03-10", "x": 1, "y": 2, "temperature": 1.0, "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Product attempts to retrieve heatmap for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve heatmap for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve heatmap for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/analytics/heatmaps/expirations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
