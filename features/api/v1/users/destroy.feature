@api/v1
Feature: Delete user

  Background:
    Given the following "accounts" exist:
      | Company | Name  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin deletes one of their users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/users/$3"
    Then the response status should be "204"
    And the current account should have 2 "users"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Admin attempts to delete a user for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/users/$3"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "users"

  Scenario: User attempts to delete themself
    Given the current account is "test1"
    And the current account has 3 "users"
    And the current account has 1 "webhookEndpoint"
    And I am a user of account "test1"
    And I send and accept JSON
    And I use an authentication token
    When I send a DELETE request to "/users/$current"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "users"
    And sidekiq should have 0 "webhook" jobs
