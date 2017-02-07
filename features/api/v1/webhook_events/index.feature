@api/v1
Feature: List webhook events

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves all webhook events for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "webhookEvents"

  Scenario: Admin retrieves a paginated list of webhook events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "webhookEvents"

  Scenario: Admin retrieves a paginated list of webhook events with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook events with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook events with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook events without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "webhookEvents"

  Scenario: Admin retrieves all webhook events with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "webhookEvents"

  Scenario: Admin retrieves all webhook events with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "webhookEvents"

  Scenario: Admin retrieves all webhook events with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook events with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves filters webhook events by event type
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And the first "webhookEvent" has the following attributes:
      """
      { "event": "real.event" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?events[]=real.event"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "webhookEvent"

  Scenario: Admin retrieves filters webhook events by event type that doesn't exist
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?events[]=bad.event"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "webhookEvents"

  Scenario: Admin attempts to retrieve all webhook events for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all webhook events for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "webhookEvents"
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
