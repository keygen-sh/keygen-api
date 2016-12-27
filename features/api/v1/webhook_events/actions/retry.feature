@api/v1
Feature: Retry webhook events

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retries a webhook event for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhookEvents"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "201"
    And the JSON response should be a "webhookEvent"
    And the current account should have 4 "webhookEvents"

  Scenario: Admin retries a webhook event for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "webhookEvents"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User retries a webhook event for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 3 "webhookEvents"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
