@api/v1
Feature: Delete machine

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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: User attempts to delete a machine for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User deletes a machine for their license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "machine"
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 0 "machines"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous user attempts to delete a machine for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to delete a machine for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
