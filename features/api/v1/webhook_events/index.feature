@api/v1
Feature: List webhook events

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves all webhook events for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "webhookEvents"
    And I use an authentication token
    When I send a GET request to "/webhook-events"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "webhookEvents"

  Scenario: Admin attempts to retrieve all webhook events for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use an authentication token
    When I send a GET request to "/webhook-events"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all webhook events for their account
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "webhookEvents"
    When I send a GET request to "/webhook-events"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
