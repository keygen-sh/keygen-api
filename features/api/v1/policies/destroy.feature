@api/v1
Feature: Delete policy

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin deletes one of their policies
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "policies"
    And I use my authentication token
    When I send a DELETE request to "/policies/$2"
    Then the response status should be "204"
    And the current account should have 2 "policies"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Admin attempts to delete a policy for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "policies"
    And I use my authentication token
    When I send a DELETE request to "/policies/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "policies"
    And sidekiq should have 0 "webhook" jobs
