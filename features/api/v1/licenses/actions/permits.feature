@api/v1
Feature: License permit actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "403"

  Scenario: Admin checks in a license by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "lastCheckInAt": null,
        "key": "test-key"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/test-key/actions/check-in"
    Then the response status should be "200"
    And the response body should be a "license" with a lastCheckIn that is not nil
    And the response body should be a "license" with a nextCheckIn that is not nil
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment checks in an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "policies"
    And all "policies" have the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 isolated "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "lastCheckInAt": null
      }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-in"
    Then the response status should be "200"
    And the response body should be a "license" with a lastCheckIn that is not nil
    And the response body should be a "license" with a nextCheckIn that is not nil
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product checks in a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "lastCheckInAt": null
      }
      """
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-in"
    Then the response status should be "200"
    And the response body should be a "license" with a lastCheckIn that is not nil
    And the response body should be a "license" with a nextCheckIn that is not nil
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License checks in itself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "lastCheckInAt": null
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-in"
    Then the response status should be "200"
    And the response body should be a "license" with a lastCheckIn that is not nil
    And the response body should be a "license" with a nextCheckIn that is not nil
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User checks in one of their licenses (license owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "lastCheckInAt": null,
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-in"
    Then the response status should be "200"
    And the response body should be a "license" with a lastCheckIn that is not nil
    And the response body should be a "license" with a nextCheckIn that is not nil
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User checks in one of their licenses (license user)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies" with the following:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-in"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User checks in one of their licenses for an unprotected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1,
        "protected": false
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "lastCheckInAt": null,
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-in"
    Then the response status should be "200"
    And the response body should be a "license" with a lastCheckIn that is not nil
    And the response body should be a "license" with a nextCheckIn that is not nil
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User checks in one of their licenses for a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1,
        "protected": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "lastCheckInAt": null,
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-in"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin suspends a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "200"
    And the response body should be a "license" that is suspended
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin suspends a license that is already suspended
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "suspended": true
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment suspends a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "suspended": true }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User suspends their license (license owner)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User suspends their license (license user)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin suspends a license by key that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 protected "policy"
    And the current account has 1 "license" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/test-key/actions/suspend"
    Then the response status should be "200"
    And the response body should be a "license" that is suspended
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product suspends a license that implements a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 protected "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "200"
    And the response body should be a "license" that is suspended
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User suspends their license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 protected "policy"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "expiry": "2016-12-01T22:53:37.000Z",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/suspend"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin reinstates a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "suspended": true
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "200"
    And the response body should be a "license" that is not suspended
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin reinstates a license that is not suspended
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment reinstates an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated+suspended "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "suspended": false }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User reinstates their license (license owner)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the last "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User reinstates their license (license owner)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" with the following:
      """
      { "suspended": true }
      """
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin reinstates a license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 protected "policy"
    And the current account has 1 "license" for the last "policy"
    And all "licenses" have the following attributes:
      """
      { "suspended": true }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "200"
    And the response body should be a "license" that is not suspended
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product reinstates a license that implements a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 protected "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "200"
    And the response body should be a "license" that is not suspended
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User reinstates their license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 protected "policy"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "suspended": true
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reinstate"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin renews a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "duration": $time.3.months.to_i }
      """
    And the current account has 1 "license" for the last "policy"
    And all "licenses" have the following attributes:
      """
      { "expiry": "2021-07-19T00:00:00.000Z" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2021-10-19T00:00:00.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin renews a license (from expiry renewal basis)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      {
        "duration": $time.1.month.to_i,
        "renewalBasis": "FROM_EXPIRY"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2021-07-19T00:00:00.000Z" }
      """
    And time is frozen at "2024-01-21T21:30:00.000Z"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2021-08-19T00:00:00.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin renews a license (from now renewal basis)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      {
        "duration": $time.1.month.to_i,
        "renewalBasis": "FROM_NOW"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2021-07-19T00:00:00.000Z" }
      """
    And time is frozen at "2024-01-21T21:30:00.000Z"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2024-02-21T21:30:00.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin renews a license (from now if expired renewal basis, not expired)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      {
        "duration": $time.1.year.to_i,
        "renewalBasis": "FROM_NOW_IF_EXPIRED"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2024-06-21T00:00:00.000Z" }
      """
    And time is frozen at "2024-01-21T21:30:00.000Z"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2025-06-21T00:00:00.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin renews a license (from now if expired renewal basis, expired)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      {
        "duration": $time.1.year.to_i,
        "renewalBasis": "FROM_NOW_IF_EXPIRED"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2023-06-21T21:30:00.000Z" }
      """
    And time is frozen at "2024-01-21T21:30:00.000Z"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2025-01-21T21:30:00.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin renews a license that belongs to a perpetual policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "duration": null }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "2021-07-19T00:00:00.000Z"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "cannot be renewed because the policy does not have a duration"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment renews a shared license
    Given the current account is "test1"
    And time is frozen at "2023-03-31T00:00:00.000Z"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "policy" with the following:
      """
      { "duration": 31556952 }
      """
    And the current account has 1 shared "license" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "expiry": "2025-03-31T00:00:00.000Z" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: User renews their license (license owner)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "duration": $time.30.days.to_i }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "expiry": "2016-12-01T22:53:37.000Z",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2016-12-31T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User renews their license (license user)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies" with the following:
      """
      { "duration": $time.30.days.to_i }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2016-12-01T22:53:37.000Z" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User renews their license without permission
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user" with the following:
      """
      { "permissions": [] }
      """
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "duration": $time.30.days.to_i }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "expiry": "2016-12-01T22:53:37.000Z",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin renews a license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 protected "policy"
    And all "policies" have the following attributes:
      """
      { "duration": $time.2.months.to_i }
      """
    And the current account has 1 "license" for the last "policy"
    And all "licenses" have the following attributes:
      """
      { "expiry": "2016-09-05T22:53:37.000Z" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2016-11-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product renews a license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 protected "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "duration": $time.30.days.to_i }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2016-09-05T22:53:37.000Z" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User renews their license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 protected "policy"
    And the last "policy" has the following attributes:
      """
      { "duration": $time.30.days.to_i }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      {
        "expiry": "2016-09-05T22:53:37.000Z",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to renew a license for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin revokes a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment revokes an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/licenses/$0/actions/revoke"
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User revokes their own license (license owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 2 "licenses" for the last "user" as "owner"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User revokes their own license (license user)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the current account has 1 "license-user" for the second "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "403"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin revokes a license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 protected "policy"
    And the current account has 3 "licenses" for the last "policy"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product revokes a license that implements a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 protected "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User revokes their own license that implements a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 protected "policy"
    And the current account has 3 "licenses" for the last "policy"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "403"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User tries to revoke another user's license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/actions/revoke"
    Then the response status should be "404"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin tries to revoke a license for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test2/licenses/$0/actions/revoke"
    Then the response status should be "401"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
