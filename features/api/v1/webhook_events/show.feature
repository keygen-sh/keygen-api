@api/v1
Feature: Show webhook event

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
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a webhook event for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "webhook-event"

  Scenario: Admin retrieves an invalid webhook event for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested webhook event 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve a webhook event for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "webhook-events"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Environment retrieves a shared webhook event for their account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 shared "webhook-events"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "webhook-event"

  Scenario: Product retrieves a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "200"
    And the response body should be a "webhook-event"

  Scenario: License retrieves a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "404"

  Scenario: User retrieves a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "404"

  Scenario: Anonymous retrieves a webhook event for an account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "401"
