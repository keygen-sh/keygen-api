@ee @clickhouse
@api/priv
Feature: Validation gauge analytics
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
    When I send a GET request to "/accounts/test1/analytics/gauges/validations"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves validations gauge for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "license" rows:
      | id                                   | name      |
      | df0beed9-1ab2-4097-9558-cd0adddf321a | License 1 |
      | c29fc20f-ec09-4cf4-8145-f910109e5705 | License 2 |
    And the current account has the following "event_log" rows:
      | id                                   | event                        | metadata                 | resource_type | resource_id                          |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | license.validation.succeeded | { "code": "VALID" }      | License       | df0beed9-1ab2-4097-9558-cd0adddf321a |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | license.validation.succeeded | { "code": "VALID" }      | License       | df0beed9-1ab2-4097-9558-cd0adddf321a |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | license.validation.succeeded | { "code": "VALID" }      | License       | c29fc20f-ec09-4cf4-8145-f910109e5705 |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | license.validation.failed    | { "code": "NO_MACHINE" } | License       | c29fc20f-ec09-4cf4-8145-f910109e5705 |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | license.validation.failed    | { "code": "EXPIRED" }    | License       | df0beed9-1ab2-4097-9558-cd0adddf321a |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/validations"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "count": 1 },
          { "metric": "validations.no-machine", "count": 1 },
          { "metric": "validations.valid", "count": 3 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves validations gauge by license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "license" rows:
      | id                                   | name      |
      | df0beed9-1ab2-4097-9558-cd0adddf321a | License 1 |
      | c29fc20f-ec09-4cf4-8145-f910109e5705 | License 2 |
    And the current account has the following "event_log" rows:
      | id                                   | event                        | metadata                 | resource_type | resource_id                          |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | license.validation.succeeded | { "code": "VALID" }      | License       | df0beed9-1ab2-4097-9558-cd0adddf321a |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | license.validation.succeeded | { "code": "VALID" }      | License       | df0beed9-1ab2-4097-9558-cd0adddf321a |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | license.validation.succeeded | { "code": "VALID" }      | License       | c29fc20f-ec09-4cf4-8145-f910109e5705 |
      | d1e6f594-7bcb-455f-971b-1e8b3ea63fd7 | license.validation.failed    | { "code": "NO_MACHINE" } | License       | c29fc20f-ec09-4cf4-8145-f910109e5705 |
      | 99e87418-ade4-460f-a5aa-a856a0059397 | license.validation.failed    | { "code": "EXPIRED" }    | License       | df0beed9-1ab2-4097-9558-cd0adddf321a |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/validations?license=df0beed9-1ab2-4097-9558-cd0adddf321a"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "count": 1 },
          { "metric": "validations.valid", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves validations gauge for isolated environment
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
      | id                                   | environment_id                       | policy_id                            |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | e44ba43d-a052-4d4c-b039-8b46a05ca4be |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |                                      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
    And the current account has the following "event_log" rows:
      | id                                   | environment_id                       | event                        | metadata                 | resource_type | resource_id                          |
      | 52785862-2da1-47a2-a6d7-be93743a12c1 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | 533cb423-17e2-4641-8140-5dddfb0cd98c | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | ff3569df-0a9e-400c-8d47-c93d042b67e7 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.succeeded | { "code": "VALID" }      | License       | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
      | d64a411f-a3c8-4136-bc82-d42d346668ef | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.failed    | { "code": "NO_MACHINE" } | License       | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 |
      | 56ac9ab0-ae64-47bc-ab3a-1c4437aba9f8 |                                      | license.validation.failed    | { "code": "EXPIRED" }    | License       | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/analytics/gauges/validations"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.valid", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves validations gauge for shared environment
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
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.succeeded | { "code": "VALID" }      | License       | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/validations?environment=shared"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "count": 1 },
          { "metric": "validations.no-machine", "count": 1 },
          { "metric": "validations.valid", "count": 2 }
        ]
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves validations gauge for global environment
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
      | id                                   | environment_id                       | policy_id                            |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 8667e7b1-3567-4ff0-8143-bd8f10dc7a21 |
      | 19a9aefc-00b9-4905-b236-ff3cca788b3e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | e44ba43d-a052-4d4c-b039-8b46a05ca4be |
      | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |                                      | 07b5b667-9d09-4f0b-a433-9cfff4111b61 |
    And the current account has the following "event_log" rows:
      | id                                   | environment_id                       | event                        | metadata                 | resource_type | resource_id                          |
      | 52785862-2da1-47a2-a6d7-be93743a12c1 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | 533cb423-17e2-4641-8140-5dddfb0cd98c | bf20fe24-351d-47d0-b3c3-2c576a63d22f | license.validation.succeeded | { "code": "VALID" }      | License       | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 |
      | ff3569df-0a9e-400c-8d47-c93d042b67e7 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.succeeded | { "code": "VALID" }      | License       | 19a9aefc-00b9-4905-b236-ff3cca788b3e |
      | d64a411f-a3c8-4136-bc82-d42d346668ef | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | license.validation.failed    | { "code": "NO_MACHINE" } | License       | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 |
      | 56ac9ab0-ae64-47bc-ab3a-1c4437aba9f8 |                                      | license.validation.failed    | { "code": "EXPIRED" }    | License       | 09d7a1f9-3c4a-401f-b6a9-839f4e35d493 |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/validations"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": [
          { "metric": "validations.expired", "count": 1 }
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
    When I send a GET request to "/accounts/test1/analytics/gauges/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve gauge for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/gauges/validations"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
