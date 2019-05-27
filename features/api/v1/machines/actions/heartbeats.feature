@api/v1
Feature: License heartbeat actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Ping endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machines"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "403"

  Scenario: Reset endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machines"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/reset-heartbeat"
    Then the response status should be "403"

  Scenario: Admin requests a machine whose heartbeat has not started
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does not requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "NOT_STARTED"
    And the JSON response should be a "machine" with a nil lastHeartbeatAt
    And the JSON response should be a "machine" with a nil nextHeartbeatAt
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin requests a machine whose heartbeat is alive
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.minute.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeatAt that is not nil
    And the JSON response should be a "machine" with a nextHeartbeatAt that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin requests a machine whose heartbeat is dead
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "DEAD"
    And the JSON response should be a "machine" with a lastHeartbeatAt that is not nil
    And the JSON response should be a "machine" with a nextHeartbeatAt that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin pings a machine's heartbeat for the first time
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeatAt that is not nil
    And the JSON response should be a "machine" with a nextHeartbeatAt that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin pings an alive machine's heartbeat
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.minute.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeatAt that is not nil
    And the JSON response should be a "machine" with a nextHeartbeatAt that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin pings a dead machine's heartbeat
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "is dead",
        "source": {
          "pointer": "/data/attributes/heartbeatStatus"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job