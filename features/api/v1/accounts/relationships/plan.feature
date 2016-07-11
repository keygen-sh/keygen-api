@api/v1
Feature: Account plan

  Scenario: Admin changes their plan
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/relationships/plan" with the following:
      """
      { "plan": "ElZw7Zko" }
      """
    Then the response status should be "200"

  Scenario: Admin attempts to change to an invalid plan
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/relationships/plan" with the following:
      """
      { "plan": "invalid" }
      """
    Then the response status should be "422"

  Scenario: Admin attempts to change plan for another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And the account "bungie" has valid billing details
    And I am an admin of account "blizzard"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/relationships/plan" with the following:
      """
      { "plan": "ElZw7Zko" }
      """
    Then the response status should be "401"
