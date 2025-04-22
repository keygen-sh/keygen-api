@api/v1
@ee
Feature: List event logs
  Background:
    Given the following "plan" rows exist:
      | id                                   | name  |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Std 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1 |
    Given the following "account" rows exist:
      | id                                   | name | slug | plan_id                              |
      | 99b7580f-d2fc-4b8f-8279-ec95fb523a17 | Std  | std  | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | c6c845b1-e9fa-4126-b89d-bdf32aa6d047 | Ent  | ent  | 44c7918c-80ab-4a13-a831-a2c46cda85c6 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "ent" is canceled
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 2 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "403"

  Scenario: Admin retrieves all logs for their Std account
    Given I am an admin of account "std"
    And the current account is "std"
    And the following "event-type" rows exist:
      | id                                   | event                             |
      | 1d721621-cbb5-4f4d-ae73-41d77a26276a | test.account.updated              |
      | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | test.license.created              |
      | 8c312434-f8e9-402f-8169-49fc1409198e | test.license.updated              |
      | 1e7c4ec0-127f-4691-b400-427333362176 | test.license.validation.succeeded |
      | 204590ba-b02e-4efd-ac32-5d1588932efa | test.license.validation.failed    |
    And the current account has the following "license" rows:
      | id                                   |
      | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
    And the current account has the following "event-log" rows:
      | whodunnit_type | whodunnit_id                         | event_type_id                        | resource_type | resource_id                          |
      | User           | 97e58005-11ab-4186-aa78-c21550f6d0ce | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | Product        | e37fa95d-7771-4e30-84be-acabdedc81ce | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | Machine       | 19ac6439-5576-4ba8-92cd-f4c17573159e |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1d721621-cbb5-4f4d-ae73-41d77a26276a | Account       | 99b7580f-d2fc-4b8f-8279-ec95fb523a17 |
    And I use an authentication token
    When I send a GET request to "/accounts/std/event-logs"
    Then the response status should be "200"
    And the response body should be an array with 9 "event-logs"

  Scenario: Admin retrieves all logs for their Ent account
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the following "event-type" rows exist:
      | id                                   | event                             |
      | 1d721621-cbb5-4f4d-ae73-41d77a26276a | test.account.updated              |
      | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | test.license.created              |
      | 8c312434-f8e9-402f-8169-49fc1409198e | test.license.updated              |
      | 1e7c4ec0-127f-4691-b400-427333362176 | test.license.validation.succeeded |
      | 204590ba-b02e-4efd-ac32-5d1588932efa | test.license.validation.failed    |
    And the current account has the following "license" rows:
      | id                                   |
      | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
    And the current account has the following "event-log" rows:
      | whodunnit_type | whodunnit_id                         | event_type_id                        | resource_type | resource_id                          |
      | User           | 97e58005-11ab-4186-aa78-c21550f6d0ce | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | Product        | e37fa95d-7771-4e30-84be-acabdedc81ce | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | Machine       | 19ac6439-5576-4ba8-92cd-f4c17573159e |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1d721621-cbb5-4f4d-ae73-41d77a26276a | Account       | c6c845b1-e9fa-4126-b89d-bdf32aa6d047 |
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "200"
    And the response body should be an array with 9 "event-logs"

  Scenario: Admin retrieves a list of logs that is automatically limited
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 250 "event-logs"
    And 50 "event-logs" have the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow"
    Then the response status should be "200"
    And the response body should be an array with 10 "event-logs"

  Scenario: Admin retrieves a list of logs with a limit
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 250 "event-logs"
    And 50 "event-logs" have the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow&limit=75"
    Then the response status should be "200"
    And the response body should be an array with 75 "event-logs"

  Scenario: Admin retrieves an unsupported paginated list of logs
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 20 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "event-logs"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/ent/event-logs?page[number]=2&page[size]=5",
        "prev": "/v1/accounts/ent/event-logs?page[number]=1&page[size]=5",
        "next": "/v1/accounts/ent/event-logs?page[number]=3&page[size]=5"
      }
      """

  Scenario: Admin retrieves a list of logs within a date range that's full
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 20 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow&limit=100"
    Then the response status should be "200"
    And the response body should be an array with 20 "event-logs"

  Scenario: Admin retrieves a list of logs within a date range that's empty
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 20 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?date[start]=2017-1-2&date[end]=2017-01-03"
    Then the response status should be "200"
    And the response body should be an array with 0 "event-logs"

  Scenario: Admin retrieves a list of logs within a date range that's too far
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 20 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?date[start]=2017-1-1&date[end]=2017-02-02"
    Then the response status should be "400"

  Scenario: Admin retrieves a list of logs within a date range that's invalid
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 20 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?date[start]=foo&date[end]=bar"
    Then the response status should be "400"

  Scenario: Admin retrieves a list of logs filtered by whodunnit
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the following "event-type" rows exist:
      | id                                   | event                             |
      | 1d721621-cbb5-4f4d-ae73-41d77a26276a | test.account.updated              |
      | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | test.license.created              |
      | 8c312434-f8e9-402f-8169-49fc1409198e | test.license.updated              |
      | 1e7c4ec0-127f-4691-b400-427333362176 | test.license.validation.succeeded |
      | 204590ba-b02e-4efd-ac32-5d1588932efa | test.license.validation.failed    |
    And the current account has the following "license" rows:
      | id                                   |
      | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
    And the current account has the following "event-log" rows:
      | whodunnit_type | whodunnit_id                         | event_type_id                        | resource_type | resource_id                          |
      | User           | 97e58005-11ab-4186-aa78-c21550f6d0ce | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | Product        | e37fa95d-7771-4e30-84be-acabdedc81ce | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | Machine       | 19ac6439-5576-4ba8-92cd-f4c17573159e |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1d721621-cbb5-4f4d-ae73-41d77a26276a | Account       | c6c845b1-e9fa-4126-b89d-bdf32aa6d047 |
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?whodunnit[type]=license&whodunnit[id]=19c0e512-d08a-408d-8d1a-6400baaf5a40"
    Then the response status should be "200"
    And the response body should be an array with 3 "event-logs"

  Scenario: Admin retrieves a list of logs filtered by resource
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the following "event-type" rows exist:
      | id                                   | event                             |
      | 1d721621-cbb5-4f4d-ae73-41d77a26276a | test.account.updated              |
      | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | test.license.created              |
      | 8c312434-f8e9-402f-8169-49fc1409198e | test.license.updated              |
      | 1e7c4ec0-127f-4691-b400-427333362176 | test.license.validation.succeeded |
      | 204590ba-b02e-4efd-ac32-5d1588932efa | test.license.validation.failed    |
      | caf802b2-9ddc-498b-8061-36309a05ca42 | test.machine.deleted              |
    And the current account has the following "license" rows:
      | id                                   |
      | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
    And the current account has the following "event-log" rows:
      | whodunnit_type | whodunnit_id                         | event_type_id                        | resource_type | resource_id                          |
      | User           | 97e58005-11ab-4186-aa78-c21550f6d0ce | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | Product        | e37fa95d-7771-4e30-84be-acabdedc81ce | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | Machine       | 19ac6439-5576-4ba8-92cd-f4c17573159e |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1d721621-cbb5-4f4d-ae73-41d77a26276a | Account       | c6c845b1-e9fa-4126-b89d-bdf32aa6d047 |
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?resource[type]=license&resource[id]=19c0e512-d08a-408d-8d1a-6400baaf5a40"
    Then the response status should be "200"
    And the response body should be an array with 6 "event-logs"

  Scenario: Admin retrieves a list of logs filtered by event
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the following "event-type" rows exist:
      | id                                   | event                             |
      | 1d721621-cbb5-4f4d-ae73-41d77a26276a | test.account.updated              |
      | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | test.license.created              |
      | 8c312434-f8e9-402f-8169-49fc1409198e | test.license.updated              |
      | 1e7c4ec0-127f-4691-b400-427333362176 | test.license.validation.succeeded |
      | 204590ba-b02e-4efd-ac32-5d1588932efa | test.license.validation.failed    |
      | caf802b2-9ddc-498b-8061-36309a05ca42 | test.machine.deleted              |
    And the current account has the following "license" rows:
      | id                                   |
      | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
    And the current account has the following "event-log" rows:
      | whodunnit_type | whodunnit_id                         | event_type_id                        | resource_type | resource_id                          |
      | User           | 97e58005-11ab-4186-aa78-c21550f6d0ce | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | Product        | e37fa95d-7771-4e30-84be-acabdedc81ce | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | Machine       | 19ac6439-5576-4ba8-92cd-f4c17573159e |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1d721621-cbb5-4f4d-ae73-41d77a26276a | Account       | c6c845b1-e9fa-4126-b89d-bdf32aa6d047 |
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?event=test.license.validation.failed"
    Then the response status should be "200"
    And the response body should be an array with 2 "event-logs"

  Scenario: Admin retrieves a list of logs filtered by request
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the following "event-type" rows exist:
      | id                                   | event                             |
      | 1d721621-cbb5-4f4d-ae73-41d77a26276a | test.account.updated              |
      | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | test.license.created              |
      | 8c312434-f8e9-402f-8169-49fc1409198e | test.license.updated              |
      | 1e7c4ec0-127f-4691-b400-427333362176 | test.license.validation.succeeded |
      | 204590ba-b02e-4efd-ac32-5d1588932efa | test.license.validation.failed    |
      | caf802b2-9ddc-498b-8061-36309a05ca42 | test.machine.deleted              |
    And the current account has the following "license" rows:
      | id                                   |
      | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |
    And the current account has the following "request-log" rows:
      | id                                   | method | url          |
      | 97708dc6-9dd2-4de1-84be-24f50287296c | POST   | /v1/licenses |
    And the current account has the following "event-log" rows:
      | whodunnit_type | whodunnit_id                         | event_type_id                        | resource_type | resource_id                          | request_log_id                       |
      | User           | 97e58005-11ab-4186-aa78-c21550f6d0ce | c257ce16-4f38-490e-8e4e-1be9ba1e8830 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 97708dc6-9dd2-4de1-84be-24f50287296c |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |                                      |
      | Product        | e37fa95d-7771-4e30-84be-acabdedc81ce | 8c312434-f8e9-402f-8169-49fc1409198e | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |                                      |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |                                      |
      | License        | 19c0e512-d08a-408d-8d1a-6400baaf5a40 | 1e7c4ec0-127f-4691-b400-427333362176 | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |                                      |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |                                      |
      |                |                                      | 204590ba-b02e-4efd-ac32-5d1588932efa | License       | 19c0e512-d08a-408d-8d1a-6400baaf5a40 |                                      |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 8c312434-f8e9-402f-8169-49fc1409198e | Machine       | 19ac6439-5576-4ba8-92cd-f4c17573159e |                                      |
      | User           | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1d721621-cbb5-4f4d-ae73-41d77a26276a | Account       | c6c845b1-e9fa-4126-b89d-bdf32aa6d047 |                                      |
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs?request=97708dc6-9dd2-4de1-84be-24f50287296c"
    Then the response status should be "200"
    And the response body should be an array with 1 "event-log"

  Scenario: Admin attempts to retrieve all logs for another account
    Given I am an admin of account "std"
    But the current account is "ent"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: Environment retrieves all logs for their environment (in isolated environment)
    Given the current account is "ent"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "event-logs"
    And the current account has 3 shared "event-logs"
    And the current account has 3 global "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "200"
    Then the response status should be "200"
    And the response body should be an array with 3 "event-logs"
    And the response body should be an array of 3 "event-logs" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  Scenario: Environment retrieves all logs for their environment (in shared environment)
    Given the current account is "ent"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "event-logs"
    And the current account has 3 shared "event-logs"
    And the current account has 3 global "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "200"
    And the response body should be an array with 6 "event-logs"
    And the response body should be an array of 3 "event-logs" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be an array of 3 "event-logs" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  Scenario: Product attempts to retrieve all logs for their account
    Given the current account is "ent"
    And the current account has 1 "product"
    And I am a product of account "ent"
    And I use an authentication token
    And the current account has 3 "event-logs"
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: License attempts to retrieve all logs for their account
    Given the current account is "ent"
    And the current account has 1 "license"
    And I am a license of account "ent"
    And I use an authentication token
    And the current account has 3 "event-logs"
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all logs for their account
    Given the current account is "ent"
    And the current account has 1 "user"
    And I am a user of account "ent"
    And I use an authentication token
    And the current account has 3 "event-logs"
    When I send a GET request to "/accounts/ent/event-logs"
    Then the response status should be "403"
    And the response body should be an array of 1 error
