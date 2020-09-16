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

  # Sanity checks
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
    And the JSON response should be a "machine" with a nil lastHeartbeat
    And the JSON response should be a "machine" with a nil nextHeartbeat
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
    And the JSON response should be a "machine" with a lastHeartbeat that is not nil
    And the JSON response should be a "machine" with a nextHeartbeat that is not nil
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
    And the JSON response should be a "machine" with a lastHeartbeat that is not nil
    And the JSON response should be a "machine" with a nextHeartbeat that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Pings
  Scenario: Anonymous pings a machine's heartbeat for the first time
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "401"
    And sidekiq should have 0 "heartbeat" jobs
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
    And the JSON response should be a "machine" with a lastHeartbeat that is not nil
    And the JSON response should be a "machine" with a nextHeartbeat that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "heartbeat" job
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin pings a machine's heartbeat for the first time by fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC",
        "lastHeartbeatAt": null
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC/actions/ping-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" with the fingerprint "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeat that is not nil
    And the JSON response should be a "machine" with a nextHeartbeat that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "heartbeat" job
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
    And the JSON response should be a "machine" with a lastHeartbeat that is not nil
    And the JSON response should be a "machine" with a nextHeartbeat that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "heartbeat" job
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
    And sidekiq should have 0 "heartbeat" jobs
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product pings a machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the current product has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeat that is not nil
    And the JSON response should be a "machine" with a nextHeartbeat that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "heartbeat" job
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product pings a machine's heartbeat that doesn't belong to them
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "403"
    And sidekiq should have 0 "heartbeat" jobs
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License pings a machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the current license has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeat within seconds of "$time.now.iso"
    And the JSON response should be a "machine" with a nextHeartbeat within seconds of "$time.10.minutes.from_now.iso"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "heartbeat" job queued in 10.5 minutes
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License pings a machine's heartbeat with a custom heartbeat duration
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": $time.1.week }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I am a license of account "test1"
    And the current license has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeat within seconds of "$time.now.iso"
    And the JSON response should be a "machine" with a nextHeartbeat within seconds of "$time.1.week.from_now.iso"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "heartbeat" job queued in 1 week
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License pings a machine's heartbeat that doesn't belong to them
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "403"
    And sidekiq should have 0 "heartbeat" jobs
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User pings an unprotected machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "lastHeartbeatAt": null
      }
      """
    And the current user has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "ALIVE"
    And the JSON response should be a "machine" with a lastHeartbeat that is not nil
    And the JSON response should be a "machine" with a nextHeartbeat that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "heartbeat" job
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User pings a protected machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "lastHeartbeatAt": null
      }
      """
    And the current user has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "403"
    And sidekiq should have 0 "heartbeat" jobs
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User pings a machine's heartbeat that doesn't belong to them
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": null }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/ping-heartbeat"
    Then the response status should be "403"
    And sidekiq should have 0 "heartbeat" jobs
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Reset
  Scenario: Anonymous resets a machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    When I send a POST request to "/accounts/test1/machines/$0/actions/reset-heartbeat"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin resets a machine's heartbeat
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/reset-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does not requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "NOT_STARTED"
    And the JSON response should be a "machine" with a nil lastHeartbeat
    And the JSON response should be a "machine" with a nil nextHeartbeat
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product resets a machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the current product has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/reset-heartbeat"
    Then the response status should be "200"
    And the JSON response should be a "machine" that does not requireHeartbeat
    And the JSON response should be a "machine" with the heartbeatStatus "NOT_STARTED"
    And the JSON response should be a "machine" with a nil lastHeartbeat
    And the JSON response should be a "machine" with a nil nextHeartbeat
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product resets a machine's heartbeat that doesn't belong to them
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/reset-heartbeat"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License resets a machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the current license has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/reset-heartbeat"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User resets a machine's heartbeat
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the current user has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "lastHeartbeatAt": "$time.1.hour.ago" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/reset-heartbeat"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job