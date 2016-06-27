@api/v1
Feature: Show user

  Scenario: Admin retrieves a user for their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And I send and accept JSON
    And I use my auth token
    And I have 3 "users"
    When I send a GET request to "/users/dgKGxar7"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Admin attempts to retrieve a user for another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And I am an admin of account "blizzard"
    But I am on the subdomain "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a GET request to "/users/dgKGxar7"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
