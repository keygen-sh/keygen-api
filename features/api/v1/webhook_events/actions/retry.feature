@api/v1
Feature: Retry webhook events

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
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "403"

  Scenario: Admin retries a webhook event for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "201"
    And the JSON response should be a "webhook-event" with the following attributes:
      """
      {
        "payload": $!webhook-events[0].payload
      }
      """
    And the JSON response should be a "webhook-event" with the following meta:
      """
      {
        "idempotencyToken": "$webhook-events[0].idempotency_token"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 4 "webhook-events"

  Scenario: Admin retries a webhook event for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: User retries a webhook event for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "webhook-events"
