@api/v1
Feature: Delete machine

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin deletes one of their machines
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "machines"
    And I use my authentication token
    When I send a DELETE request to "/machines/$2"
    Then the response status should be "204"
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs

  Scenario: User attempts to delete a machine for their account
    Given I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my authentication token
    When I send a DELETE request to "/machines/$1"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs

  Scenario: User deletes a machine for their license
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my authentication token
    And the current user has 1 "machine"
    When I send a DELETE request to "/machines/$0"
    Then the response status should be "204"
    And the current account should have 0 "machines"
    And sidekiq should have 1 "webhook" job

  Scenario: Anonymous user attempts to delete a machine for their account
    Given I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "machines"
    When I send a DELETE request to "/machines/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to delete a machine for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "machines"
    And I use my authentication token
    When I send a DELETE request to "/machines/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
