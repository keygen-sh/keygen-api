@api/v1
Feature: Show webhook event

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves a webhook event for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "200"
    And the JSON response should be a "webhookEvent"

  Scenario: Admin retrieves an invalid webhook event for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/invalid"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a webhook event for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: Product retrieves a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhookEvents"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "200"
    And the JSON response should be a "webhookEvent"

  Scenario: User retrieves a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhookEvents"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-events/$0"
    Then the response status should be "403"
