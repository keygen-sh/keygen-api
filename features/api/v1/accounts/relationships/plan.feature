@api/v1
Feature: Account plan

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin changes their plan
    Given the account "test1" has valid billing details
    And I am an admin of account "test1"
    And I use my auth token
    When I send a POST request to "/accounts/$0/relationships/plan" with the following:
      """
      { "plan": "$plan[0]" }
      """
    Then the response status should be "200"

  Scenario: Admin attempts to change to an invalid plan
    Given the account "test1" has valid billing details
    And I am an admin of account "test1"
    And I use my auth token
    When I send a POST request to "/accounts/$0/relationships/plan" with the following:
      """
      { "plan": "invalid" }
      """
    Then the response status should be "422"

  Scenario: Admin attempts to change plan for another account
    Given the account "test1" has valid billing details
    And I am an admin of account "test2"
    And I use my auth token
    When I send a POST request to "/accounts/$0/relationships/plan" with the following:
      """
      { "plan": "$plan[0]" }
      """
    Then the response status should be "401"
