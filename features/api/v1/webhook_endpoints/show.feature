@api/v1
Feature: Show webhook endpoint

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
    When I send a GET request to "/accounts/test1/webhook-endpoints/$2"
    Then the response status should be "403"

  Scenario: Admin retrieves a webhook endpoint for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints/$0"
    Then the response status should be "200"
    And the JSON response should be a "webhookEndpoint"

  Scenario: Admin retrieves an invalid webhook endpoint for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints/invalid"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a webhook endpoint for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
