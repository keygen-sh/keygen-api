@api/v1
Feature: Delete user

  Scenario: Admin deletes one of their users
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And the current account has 3 "users"
    And I send and accept JSON
    And I use my auth token
    When I send a DELETE request to "/users/dgKGxar7"
    Then the response status should be "204"
    And the current account should have 2 "users"

  Scenario: Admin attempts to delete a user for another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And I am an admin of account "blizzard"
    But I am on the subdomain "bungie"
    And the current account has 3 "users"
    And I send and accept JSON
    And I use my auth token
    When I send a DELETE request to "/users/dgKGxar7"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "users"

  Scenario: User attempts to delete themself
    Given there exists an account "bungie"
    But I am on the subdomain "bungie"
    And the current account has 3 "users"
    And I am a user of account "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a DELETE request to "/users/dgKGxar7"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "users"
