@api/v1
Feature: Delete policy

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
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their policies
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "204"
    And the current account should have 2 "policies"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin attempts to delete a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "policies"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
