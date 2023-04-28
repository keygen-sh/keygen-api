@api/v1
Feature: List webhook events

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
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "403"

  Scenario: Admin retrieves all webhook events for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an array with 3 "webhook-events"

  @ee
  Scenario: Environment retrieves all isolated webhook events for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "webhook-events"
    And the current account has 3 shared "webhook-events"
    And the current account has 3 global "webhook-events"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?environment=isolated"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an array with 3 "webhook-events"

  @ee
  Scenario: Environment retrieves all shared webhook events for their account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "webhook-events"
    And the current account has 3 shared "webhook-events"
    And the current account has 3 global "webhook-events"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?environment=shared"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an array with 6 "webhook-events"

  Scenario: Product retrieves all webhook events for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an array with 3 "webhook-events"

  Scenario: Admin retrieves a paginated list of webhook events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "webhook-events"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/webhook-events?page[number]=2&page[size]=5",
        "prev": "/v1/accounts/test1/webhook-events?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/webhook-events?page[number]=3&page[size]=5"
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves the first page a paginated list of webhook events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 17 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "webhook-events"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/webhook-events?page[number]=1&page[size]=5",
        "prev": null,
        "next": "/v1/accounts/test1/webhook-events?page[number]=2&page[size]=5"
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves the last page of a paginated list of webhook events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 22 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=5&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 2 "webhook-events"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/webhook-events?page[number]=5&page[size]=5",
        "prev": "/v1/accounts/test1/webhook-events?page[number]=4&page[size]=5",
        "next": null
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves a paginated list of webhook events with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook events with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook events with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook events without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "200"
    And the response body should be an array with 10 "webhook-events"

  Scenario: Admin retrieves all webhook events with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "webhook-events"

  Scenario: Admin retrieves all webhook events with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "webhook-events"

  Scenario: Admin retrieves all webhook events with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook events with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?limit=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves filters webhook events by event type
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And the first "webhook-event" has the following attributes:
      """
      { "eventTypeId": "$event_types[real.event]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?events[]=real.event"
    Then the response status should be "200"
    And the response body should be an array with 1 "webhook-event"

  Scenario: Admin retrieves filters webhook events by event type that doesn't exist
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events?events[]=bad.event"
    Then the response status should be "200"
    And the response body should be an array with 0 "webhook-events"

  Scenario: Admin attempts to retrieve all webhook events for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: License attempts to retrieve all webhook events for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 3 "webhook-events"
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all webhook events for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "webhook-events"
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: Anonymous attempts to retrieve all webhook events for an account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    When I send a GET request to "/accounts/test1/webhook-events"
    Then the response status should be "401"
    And the response body should be an array of 1 error
