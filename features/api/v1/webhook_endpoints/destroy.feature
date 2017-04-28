@api/v1
Feature: Delete webhook endpoint

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
    And the current account has 3 "webhookEndpoints"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$2"
    Then the response status should be "403"

  Scenario: Admin deletes one of their webhook endpoints
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$2"
    Then the response status should be "204"
    And the current account should have 2 "webhookEndpoints"

  Scenario: User attempts to delete a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "webhookEndpoints"

  Scenario: Anonymous user attempts to delete a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "webhookEndpoints"

  Scenario: Admin attempts to delete a webhook endpoint for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "webhookEndpoints"
