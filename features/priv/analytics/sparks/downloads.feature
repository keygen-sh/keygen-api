@ee @clickhouse
@api/priv
Feature: Download spark analytics
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
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves download series for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "product" rows:
      | id                                   | name      |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Product 1 |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | Product 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 1.0.0   | stable  |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | fa48996c-9c98-41c1-a2c3-21de98aefafe | 2.0.0   | stable  |
    And the current account has the following "release_download_spark" rows:
      | product_id                           | release_id                           | count | created_date | created_at           |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | a499bb93-9902-4b52-8a04-76944ad7f660 | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads?date[start]=2100-08-20&date[end]=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "downloads", "date": "2100-08-23", "count": 8 },
          { "metric": "downloads", "date": "2100-08-24", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves download series filtered by product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "product" rows:
      | id                                   | name      |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Product 1 |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | Product 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 1.0.0   | stable  |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | fa48996c-9c98-41c1-a2c3-21de98aefafe | 2.0.0   | stable  |
    And the current account has the following "release_download_spark" rows:
      | product_id                           | release_id                           | count | created_date | created_at           |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | a499bb93-9902-4b52-8a04-76944ad7f660 | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads?product=c9e2cd2e-2543-4d3f-8563-d0bf0b11e233&date[start]=2100-08-20&date[end]=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "downloads", "date": "2100-08-23", "count": 5 },
          { "metric": "downloads", "date": "2100-08-24", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves download series filtered by package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "product" rows:
      | id                                   | name      |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Product 1 |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      |
      | 46e034e3-1c8e-4e3b-8a6b-76c2e2ec3694 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Package 1 | pkg1     |
      | f6cac50e-7153-4b0d-897d-3f1a79a13304 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Package 2 | pkg2     |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | package_id                           | version | channel |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 46e034e3-1c8e-4e3b-8a6b-76c2e2ec3694 | 1.0.0   | stable  |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | f6cac50e-7153-4b0d-897d-3f1a79a13304 | 2.0.0   | stable  |
    And the current account has the following "release_download_spark" rows:
      | product_id                           | package_id                           | release_id                           | count | created_date | created_at           |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 46e034e3-1c8e-4e3b-8a6b-76c2e2ec3694 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | f6cac50e-7153-4b0d-897d-3f1a79a13304 | a499bb93-9902-4b52-8a04-76944ad7f660 | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 46e034e3-1c8e-4e3b-8a6b-76c2e2ec3694 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads?package=46e034e3-1c8e-4e3b-8a6b-76c2e2ec3694&date[start]=2100-08-20&date[end]=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "downloads", "date": "2100-08-23", "count": 5 },
          { "metric": "downloads", "date": "2100-08-24", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves download series filtered by release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "product" rows:
      | id                                   | name      |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Product 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 1.0.0   | stable  |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 2.0.0   | stable  |
    And the current account has the following "release_download_spark" rows:
      | product_id                           | release_id                           | count | created_date | created_at           |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | a499bb93-9902-4b52-8a04-76944ad7f660 | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads?release=bf9b523f-dd65-48a2-9512-fb66ba6c3714&date[start]=2100-08-20&date[end]=2100-08-27"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "downloads", "date": "2100-08-23", "count": 5 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves downloads spark for isolated environment
    Given the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name      |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated  |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe |                                      | Global    |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | environment_id                       | version | channel |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 1.0.0   | stable  |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | fa48996c-9c98-41c1-a2c3-21de98aefafe |                                      | 2.0.0   | stable  |
    And the current account has the following "release_artifact" rows:
      | id                                   | release_id                           | environment_id                       |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | bf20fe24-351d-47d0-b3c3-2c576a63d22f |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | a499bb93-9902-4b52-8a04-76944ad7f660 |                                      |
    And the current account has the following "event_log" rows:
      | environment_id                       | event               | metadata                                                                                                                                 | resource_type   | resource_id                          |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | artifact.downloaded | { "product": "c9e2cd2e-2543-4d3f-8563-d0bf0b11e233", "release": "bf9b523f-dd65-48a2-9512-fb66ba6c3714", "version": "1.0.0" }             | ReleaseArtifact | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | artifact.downloaded | { "product": "c9e2cd2e-2543-4d3f-8563-d0bf0b11e233", "release": "bf9b523f-dd65-48a2-9512-fb66ba6c3714", "version": "1.0.0" }             | ReleaseArtifact | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      |                                      | artifact.downloaded | { "product": "fa48996c-9c98-41c1-a2c3-21de98aefafe", "release": "a499bb93-9902-4b52-8a04-76944ad7f660", "version": "2.0.0" }             | ReleaseArtifact | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
      |                                      | artifact.downloaded | { "product": "fa48996c-9c98-41c1-a2c3-21de98aefafe", "release": "a499bb93-9902-4b52-8a04-76944ad7f660", "version": "2.0.0" }             | ReleaseArtifact | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
    And the current account has the following "release_download_spark" rows:
      | environment_id                       | product_id                           | release_id                           | count | created_date | created_at           |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      |                                      | fa48996c-9c98-41c1-a2c3-21de98aefafe | a499bb93-9902-4b52-8a04-76944ad7f660 | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      |                                      | fa48996c-9c98-41c1-a2c3-21de98aefafe | a499bb93-9902-4b52-8a04-76944ad7f660 | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads?date[start]=2100-08-20&date[end]=2100-08-30"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "downloads", "date": "2100-08-23", "count": 5 },
          { "metric": "downloads", "date": "2100-08-30", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves download series with no data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": []
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves download series with start date too old
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads?date[start]=2020-01-01&date[end]=2024-01-15"
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

  Scenario: Admin retrieves download series with end date in future
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-01-15T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads?date[start]=2024-01-01&date[end]=2099-01-01"
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

  Scenario: Product attempts to retrieve download series for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve download series for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve download series for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/downloads"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
