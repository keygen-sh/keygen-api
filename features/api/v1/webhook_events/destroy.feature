@api/v1
Feature: Delete webhook event

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Event should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-events/$2"
    Then the response status should be "403"

  Scenario: Admin deletes one of their webhook events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-events/$2"
    Then the response status should be "204"
    And the current account should have 2 "webhook-events"
    And the response should contain a valid signature header for "test1"

  @ee
  Scenario: Environment attempts to delete an isolated webhook event for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "webhook-events"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-events/$1?environment=isolated"
    Then the response status should be "204"

  Scenario: Product attempts to delete a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-events/$1"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: License attempts to delete a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-events/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: User attempts to delete a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-events/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: Anonymous user attempts to delete a webhook event for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    When I send a DELETE request to "/accounts/test1/webhook-events/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: Admin attempts to delete a webhook event for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-events/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"
