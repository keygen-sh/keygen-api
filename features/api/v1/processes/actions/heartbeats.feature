@api/v1
Feature: Process heartbeat actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Ping endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "process"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "403"

  Scenario: Admin pings a process's heartbeat
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "process"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin pings a process's heartbeat that has met their process limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "processLeasingStrategy": "PER_MACHINE",
        "maxProcesses": 5
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 5 "processes" for the last "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "process"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin pings a dead process's heartbeat
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "process"
    And the first "process" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "code": "PROCESS_HEARTBEAT_DEAD",
        "detail": "is dead"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin pings a dead process's heartbeat that supports resurrection (period not passed)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "heartbeatResurrectionStrategy": "5_MINUTE_REVIVE",
        "heartbeatDuration": $time.5.minutes
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And the first "process" has the following attributes:
      """
      { "lastHeartbeatAt": "2022-10-16T14:45:48.000Z" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T14:57:48.000Z",
        "status": "RESURRECTED"
      }
      """
    And the response should contain a valid signature header for "test1"
    # NOTE(ezekg) To assert that the RESURRECTED status is transient
    And the first "process" should have the status "ALIVE"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin pings a dead process's heartbeat that supports resurrection (period passed)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "heartbeatResurrectionStrategy": "5_MINUTE_REVIVE",
        "heartbeatDuration": $time.5.minutes
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And the first "process" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.11.minutes.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "code": "PROCESS_HEARTBEAT_DEAD",
        "detail": "is dead"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  @ee
  Scenario: Environment pings an isolated process's heartbeat
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "process"
    And I am an environment of account "test1"
    And I use an authentication token
    And time is frozen at "2022-10-16T14:52:48.000Z"
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  @ee
  Scenario: Environment pings a shared process's heartbeat
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "process"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And time is frozen at "2022-10-16T14:52:48.000Z"
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Product pings a process's heartbeat
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Product pings a process for a different product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "process"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License pings a process's heartbeat
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: License pings a process's heartbeat with a custom heartbeat duration
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": $time.2.weeks }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-30T14:52:48.000Z",
        "status": "ALIVE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: License pings a process's heartbeat that doesn't belong to them
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "process"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User pings an unprotected process's heartbeat (license owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    # FIXME(ezekg) Freezing later to preserve user order
    And time is frozen at "2022-10-16T14:52:48.000Z"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: User pings an unprotected process's heartbeat (license user, machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And the current account has 1 "process" for the last "machine"
    And time is frozen at "2022-10-16T14:52:48.000Z"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: User pings an unprotected process's heartbeat (license user, not owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User pings a protected process's heartbeat
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    # FIXME(ezekg) Freezing later to preserve user order
    And time is frozen at "2022-10-16T14:52:48.000Z"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: User pings a process's heartbeat that doesn't belong to them
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "process"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes/$0/actions/ping"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
