@ee @clickhouse
@api/priv
Feature: Validation spark analytics
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
    When I send a GET request to "/accounts/test1/analytics/sparks/validations"
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
    When I send a GET request to "/accounts/test1/analytics/sparks/validations?date[start]=2100-08-20&date[end]=2100-08-27"
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
    When I send a GET request to "/accounts/test1/analytics/sparks/validations?license=bf9b523f-dd65-48a2-9512-fb66ba6c3714&date[start]=2100-08-20&date[end]=2100-08-27"
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

  Scenario: Admin retrieves validations spark for isolated environment
    Given the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
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
      | id                                   | environment_id                       | policy_id                            |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | e44ba43d-a052-4d4c-b039-8b46a05ca4be |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |                                      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
    And the current account has the following "event_log" rows:
      | environment_id                       | event                        | metadata                 | resource_type | resource_id                          |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.succeeded | { "code": "VALID" }      | License       | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.failed    | { "code": "NO_MACHINE" } | License       | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 |
      |                                      | license.validation.failed    | { "code": "EXPIRED" }    | License       | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |
    And the current account has the following "license_validation_spark" rows:
      | environment_id                       | license_id                           | validation_code | count | created_date | created_at           |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | VALID           | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 19a9aefc-00b9-4905-b236-ff3cca788b3e | VALID           | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | EXPIRED         | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | VALID           | 8     | 2100-08-28   | 2100-08-24T00:00:00Z |
      |                                      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | SUSPENDED       | 1     | 2100-08-29   | 2100-08-24T00:00:00Z |
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/analytics/sparks/validations"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "date": "2100-08-24", "count": 2 },
          { "metric": "validations.valid", "date": "2100-08-23", "count": 5 },
          { "metric": "validations.valid", "date": "2100-08-30", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves validations spark for shared environment
    Given the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
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
      | id                                   | environment_id                       | policy_id                            |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | e44ba43d-a052-4d4c-b039-8b46a05ca4be |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |                                      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
    And the current account has the following "event_log" rows:
      | environment_id                       | event                        | metadata                 | resource_type | resource_id                          |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.succeeded | { "code": "VALID" }      | License       | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.failed    | { "code": "NO_MACHINE" } | License       | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 |
      |                                      | license.validation.failed    | { "code": "EXPIRED" }    | License       | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |
    And the current account has the following "license_validation_spark" rows:
      | environment_id                       | license_id                           | validation_code | count | created_date | created_at           |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | VALID           | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 19a9aefc-00b9-4905-b236-ff3cca788b3e | VALID           | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | EXPIRED         | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | VALID           | 8     | 2100-08-28   | 2100-08-24T00:00:00Z |
      |                                      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | SUSPENDED       | 1     | 2100-08-29   | 2100-08-24T00:00:00Z |
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/validations?environment=shared"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "date": "2100-08-30", "count": 1 },
          { "metric": "validations.no-machine", "date": "2100-08-30", "count": 1 },
          { "metric": "validations.suspended", "date": "2100-08-29", "count": 1 },
          { "metric": "validations.valid", "date": "2100-08-23", "count": 3 },
          { "metric": "validations.valid", "date": "2100-08-28", "count": 8 },
          { "metric": "validations.valid", "date": "2100-08-30", "count": 1 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves validations spark for global environment
    Given the current account is "test1"
    And time is frozen at "2100-08-30T00:00:00.000Z"
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
      | id                                   | environment_id                       | policy_id                            |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | e44ba43d-a052-4d4c-b039-8b46a05ca4be |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |                                      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
    And the current account has the following "event_log" rows:
      | environment_id                       | event                        | metadata                 | resource_type | resource_id                          |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.succeeded | { "code": "VALID" }      | License       | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.failed    | { "code": "NO_MACHINE" } | License       | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 |
      |                                      | license.validation.failed    | { "code": "EXPIRED" }    | License       | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |
    And the current account has the following "license_validation_spark" rows:
      | environment_id                       | license_id                           | validation_code | count | created_date | created_at           |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | VALID           | 5     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 19a9aefc-00b9-4905-b236-ff3cca788b3e | VALID           | 3     | 2100-08-23   | 2100-08-23T00:00:00Z |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | EXPIRED         | 2     | 2100-08-24   | 2100-08-24T00:00:00Z |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | VALID           | 8     | 2100-08-28   | 2100-08-24T00:00:00Z |
      |                                      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 | SUSPENDED       | 1     | 2100-08-29   | 2100-08-24T00:00:00Z |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/validations"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "date": "2100-08-30", "count": 1 },
          { "metric": "validations.suspended", "date": "2100-08-29", "count": 1 }
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
    When I send a GET request to "/accounts/test1/analytics/sparks/validations"
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
    When I send a GET request to "/accounts/test1/analytics/sparks/validations?date[start]=2020-01-01&date[end]=2024-01-15"
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
    When I send a GET request to "/accounts/test1/analytics/sparks/validations?date[start]=2024-01-01&date[end]=2099-01-01"
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
    When I send a GET request to "/accounts/test1/analytics/sparks/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve validation series for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve validation series for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/sparks/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
