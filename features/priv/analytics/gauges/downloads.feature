@ee @clickhouse
@api/priv
Feature: Download gauge analytics
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
    When I send a GET request to "/accounts/test1/analytics/gauges/downloads"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves downloads gauge for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name      |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Product 1 |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | Product 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 1.0.0   | stable  |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | fa48996c-9c98-41c1-a2c3-21de98aefafe | 2.0.0   | stable  |
    And the current account has the following "release_artifact" rows:
      | id                                   | release_id                           |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | a499bb93-9902-4b52-8a04-76944ad7f660 |
    And the current account has the following "event_log" rows:
      | id                                   | event               | metadata                                                                                                                                 | resource_type   | resource_id                          |
      | 52785862-2da1-47a2-a6d7-be93743a12c1 | artifact.downloaded | { "product": "c9e2cd2e-2543-4d3f-8563-d0bf0b11e233", "release": "bf9b523f-dd65-48a2-9512-fb66ba6c3714", "version": "1.0.0" }             | ReleaseArtifact | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | 533cb423-17e2-4641-8140-5dddfb0cd98c | artifact.downloaded | { "product": "c9e2cd2e-2543-4d3f-8563-d0bf0b11e233", "release": "bf9b523f-dd65-48a2-9512-fb66ba6c3714", "version": "1.0.0" }             | ReleaseArtifact | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | ff3569df-0a9e-400c-8d47-c93d042b67e7 | artifact.downloaded | { "product": "fa48996c-9c98-41c1-a2c3-21de98aefafe", "release": "a499bb93-9902-4b52-8a04-76944ad7f660", "version": "2.0.0" }             | ReleaseArtifact | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/downloads"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "downloads", "count": 3 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves downloads gauge filtered by product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name      |
      | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | Product 1 |
      | fa48996c-9c98-41c1-a2c3-21de98aefafe | Product 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | bf9b523f-dd65-48a2-9512-fb66ba6c3714 | c9e2cd2e-2543-4d3f-8563-d0bf0b11e233 | 1.0.0   | stable  |
      | a499bb93-9902-4b52-8a04-76944ad7f660 | fa48996c-9c98-41c1-a2c3-21de98aefafe | 2.0.0   | stable  |
    And the current account has the following "release_artifact" rows:
      | id                                   | release_id                           |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf9b523f-dd65-48a2-9512-fb66ba6c3714 |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | a499bb93-9902-4b52-8a04-76944ad7f660 |
    And the current account has the following "event_log" rows:
      | id                                   | event               | metadata                                                                                                                                 | resource_type   | resource_id                          |
      | 52785862-2da1-47a2-a6d7-be93743a12c1 | artifact.downloaded | { "product": "c9e2cd2e-2543-4d3f-8563-d0bf0b11e233", "release": "bf9b523f-dd65-48a2-9512-fb66ba6c3714", "version": "1.0.0" }             | ReleaseArtifact | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | 533cb423-17e2-4641-8140-5dddfb0cd98c | artifact.downloaded | { "product": "c9e2cd2e-2543-4d3f-8563-d0bf0b11e233", "release": "bf9b523f-dd65-48a2-9512-fb66ba6c3714", "version": "1.0.0" }             | ReleaseArtifact | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | ff3569df-0a9e-400c-8d47-c93d042b67e7 | artifact.downloaded | { "product": "fa48996c-9c98-41c1-a2c3-21de98aefafe", "release": "a499bb93-9902-4b52-8a04-76944ad7f660", "version": "2.0.0" }             | ReleaseArtifact | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/downloads?product=c9e2cd2e-2543-4d3f-8563-d0bf0b11e233"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "downloads", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves downloads gauge with no data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/downloads"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": []
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Product attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/downloads"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/downloads"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/downloads"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
