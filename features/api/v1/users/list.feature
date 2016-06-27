@api/v1
Feature: List users

  Scenario: Admin retrieves all users for their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And I send and accept JSON
    And I use my auth token
    And I have 3 "users"
    When I send a GET request to "/v1/users"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "users"

  Scenario: Admin attempts to retrieve all users for another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And I am an admin of account "blizzard"
    But I am on the subdomain "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a GET request to "/v1/users"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
