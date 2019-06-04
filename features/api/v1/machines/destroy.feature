@api/v1
Feature: Delete machine

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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their machines by fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "foo-bar-baz" }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/foo-bar-baz"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their machines by UUID fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "a06b4343-d2cf-45e7-b9a2-b11c618993f3" }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/a06b4343-d2cf-45e7-b9a2-b11c618993f3"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete a machine that belongs to another user
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User deletes a machine for their unprotected license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "machine"
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 0 "machines"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User deletes a machine for their protected license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "machine"
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License deletes a machine for their license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the current account has 1 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 0 "machines"
    And the current token should have the following attributes:
      """
      {
        "deactivations": 1
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License deletes a machine for their license but they've hit their deactivation limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the current account has 1 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      {
        "maxDeactivations": 1,
        "deactivations": 1
      }
      """
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "422"
    And the current account should have 1 "machine"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "exceeds maximum allowed (1)",
        "code": "DEACTIVATIONS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/deactivations"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License deletes a machine that belongs to another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the current account has 1 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 1 "machine"
    And the current token should have the following attributes:
      """
      {
        "deactivations": 0
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous user attempts to delete a machine for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete a machine for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
