@ee @clickhouse
@api/priv
Feature: Stat analytics
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
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves machines count for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": {
          "count": 5
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves users count for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/users"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": {
          "count": 3
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves licenses count for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 4 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/licenses"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": {
          "count": 4
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves ALUs for their account
    Given the current account is "test1"
    And time is frozen at "2024-03-07T00:00:00.000Z"
    And the current account has the following "user" rows:
      | id                                   | email                                         | created_at               | banned_at                |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | new.user.active@keygen.example                | 2024-02-07T00:00:00.000Z |                          |
      | 96faacd6-16e6-4661-8e16-9e8064fbeb0a | new.user.active.2@keygen.example              | 2024-02-07T00:00:00.000Z |                          |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | old.user.inactive@keygen.example              | 2023-02-07T00:00:00.000Z |                          |
      | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | old.user.new.license@keygen.example           | 2023-02-07T00:00:00.000Z |                          |
      | 6f87a593-fba5-4be3-814f-c5ef1208f52b | old.user.old.license@keygen.example           | 2023-02-07T00:00:00.000Z |                          |
      | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | old.user.mixed.licenses@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | old.user.valid.license@keygen.example         | 2023-02-07T00:00:00.000Z |                          |
      | 44dce69e-bb15-4915-9adc-074f8b57a61c | old.user.checkout.license@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | a04ac105-ec12-4dc9-89d0-06dd99124349 | old.user.checkin.license@keygen.example       | 2023-02-07T00:00:00.000Z |                          |
      | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | old.user.mixed.licenses.2@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | be3ea9f0-e7ca-4eea-9326-a7658c247e5f | old.user.new.user.license@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | c05d47fc-0a16-46e9-b601-f287b2382026 | old.user.old.user.license@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | 4dface92-de40-4950-ab0e-f79e611884f5 | old.user.mixed.user.license@keygen.example    | 2023-02-07T00:00:00.000Z |                          |
      | b2966243-fd44-4649-9724-a0ba1e5f4384 | old.user.valid.user.license@keygen.example    | 2023-02-07T00:00:00.000Z |                          |
      | 80c38300-be81-414c-a628-dc3db640fe5a | old.user.checkout.user.license@keygen.example | 2023-02-07T00:00:00.000Z |                          |
      | 176bd46a-fccc-49e2-9205-2e728efed291 | old.user.checkin.user.license@keygen.example  | 2023-02-07T00:00:00.000Z |                          |
      | 227fba93-263f-4718-b982-b5be38fbc3c1 | old.user.old.user.license.2@keygen.example    | 2023-02-07T00:00:00.000Z |                          |
      | 5e360440-acd7-4c63-973e-5133b2ebfdbb | banned.user@keygen.example                    | 2024-02-07T00:00:00.000Z | 2024-01-07T00:00:00.000Z |
    And the current account has the following "license" rows:
      | id                                   | name                                   | user_id                              | created_at               | last_validated_at        | last_check_out_at        | last_check_in_at         |
      | df0beed9-1ab2-4097-9558-cd0adddf321a | New owned license w/ no activity       | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | c29fc20f-ec09-4cf4-8145-f910109e5705 | Old owned license w/ no activity       | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | af5c7d44-26bd-4bfd-9dcc-8aed721308ab | Old owned license w/ recent validation | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | ee26deca-5688-451f-86bd-801291dd2d24 | Old owned license w/ recent checkout   | 44dce69e-bb15-4915-9adc-074f8b57a61c | 2023-02-07T00:00:00.000Z |                          | 2024-02-07T00:00:00.000Z |                          |
      | e4304d3f-4d6c-4faf-86ee-0ddbb3324aa5 | Old owned license w/ recent checkin    | a04ac105-ec12-4dc9-89d0-06dd99124349 | 2023-02-07T00:00:00.000Z |                          |                          | 2024-02-07T00:00:00.000Z |
      | 2022a17f-87e4-4b4c-a07b-e28b45f43d6a | Old owned license w/ no activity       | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | 09d2e554-eb02-44a9-93d2-ab7a14bc5897 | New license w/ no activity             |                                      | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | New license w/ no activity             |                                      | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | 69e2c722-7c90-4456-8850-3363f19486b1 | New license w/ recent validation       |                                      | 2024-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de | Old license w/ no activity             |                                      | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | ce5fc968-cff0-4b41-9f5d-cb42c330d01c | Old license w/ recent validation       | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z | 2024-03-07T00:00:00.000Z |                          |                          |
      | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 | Old license w/ recent checkout         |                                      | 2023-02-07T00:00:00.000Z |                          | 2024-03-07T00:00:00.000Z |                          |
      | 894f1d07-d229-4b56-96bc-a3a7cceacb14 | Old license w/ recent checkin          |                                      | 2023-02-07T00:00:00.000Z |                          |                          | 2024-03-07T00:00:00.000Z |
      | 98dd1804-a865-4d63-b194-b37358cebd26 | Old license w/ old validation          | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z | 2023-03-07T00:00:00.000Z |                          |                          |
      | 30a61489-b658-41ff-9099-5a028dc9fc06 | Old license w/ old checkout            |                                      | 2023-02-07T00:00:00.000Z |                          | 2023-03-07T00:00:00.000Z |                          |
      | 7b119973-398d-4b8f-be5f-78613d8ba6f0 | Old license w/ old checkin             | 6f87a593-fba5-4be3-814f-c5ef1208f52b | 2023-02-07T00:00:00.000Z |                          |                          | 2023-03-07T00:00:00.000Z |
    And the current account has the following "license_user" rows:
      | id                                   | license_id                           | user_id                              |
      | 85bf9110-7da9-4967-a847-34d7144a2bb8 | ee26deca-5688-451f-86bd-801291dd2d24 | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd |
      | f98f7bda-9ef3-4711-8467-8234342dc8ec | ce5fc968-cff0-4b41-9f5d-cb42c330d01c | 4dface92-de40-4950-ab0e-f79e611884f5 |
      | 07d185a2-5b7a-4c73-9896-a8f1a8bd8842 | 2022a17f-87e4-4b4c-a07b-e28b45f43d6a | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd |
      | 7686f2ab-8979-4257-b44b-dd60bc947b9a | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | be3ea9f0-e7ca-4eea-9326-a7658c247e5f |
      | 0bf8c414-8505-4e8e-9d5f-800c387906bc | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de | 4dface92-de40-4950-ab0e-f79e611884f5 |
      | bbd3becd-1abf-4a5c-860e-18b53d14d10a | ce5fc968-cff0-4b41-9f5d-cb42c330d01c | b2966243-fd44-4649-9724-a0ba1e5f4384 |
      | 8f4875ab-7d95-439a-aed9-22cbc73c3938 | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 | 80c38300-be81-414c-a628-dc3db640fe5a |
      | 48403a79-09a1-4460-ba28-3d0fa7bbab09 | 894f1d07-d229-4b56-96bc-a3a7cceacb14 | 176bd46a-fccc-49e2-9205-2e728efed291 |
      | dc1fbbc4-51e9-4bf3-88e5-07e8da65ca84 | 30a61489-b658-41ff-9099-5a028dc9fc06 | 227fba93-263f-4718-b982-b5be38fbc3c1 |
      | 8272cd86-5884-4b2c-8946-b62532877035 | 98dd1804-a865-4d63-b194-b37358cebd26 | c05d47fc-0a16-46e9-b601-f287b2382026 |
      | fcdc2b34-8ccd-407e-b59b-86bf99e21b21 | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | 5e360440-acd7-4c63-973e-5133b2ebfdbb |
      | 5cbe9d2b-a868-4573-9eb8-86509ff23e01 | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | 4dface92-de40-4950-ab0e-f79e611884f5 |
    And the current account has the following "machine" rows:
      | id                                   | license_id                           | fingerprint                      |
      | 7f1d7a2e-6c3e-4f5a-956a-49f2b43197e2 | c29fc20f-ec09-4cf4-8145-f910109e5705 | 379a557f6d2342df932f4182a5290c87 |
      | 319bc0f0-5c91-4eba-9a31-910a38bdb67f | af5c7d44-26bd-4bfd-9dcc-8aed721308ab | a2b536fd10b74653899b904de16533f5 |
      | 30af2a1d-b999-4598-a4f8-546a74ddc93c | 2022a17f-87e4-4b4c-a07b-e28b45f43d6a | 39687fbe1531485482b9453037c602a7 |
      | 25515b44-6921-4b14-9f89-7e1510beb5bd | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de | d2f63b6f664a45339d484b2f2b30f5b0 |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/alus"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": {
          "count": 14
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
    And time is unfrozen

  Scenario: Admin retrieves invalid metric
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/invalid"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves machines count for isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "machines"
    And the current account has 2 global "machines"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": {
          "count": 3
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves machines count for shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 shared "machines"
    And the current account has 2 global "machines"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": {
          "count": 5
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves machines count for global environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "machines"
    And the current account has 2 global "machines"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "data": {
          "count": 2
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Product attempts to retrieve stats for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: User attempts to retrieve stats for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: License attempts to retrieve stats for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/stats/machines"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs
