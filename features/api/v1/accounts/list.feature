@api/v1
Feature: List accounts

  Scenario: Admin attempts to retrieve all accounts
    Given there exists another account "blizzard"
    And I am an admin of account "blizzard"
    And I send and accept JSON
    And I use my auth token
    When I send a GET request to "/accounts"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all accounts
    Given there exists another account "blizzard"
    And the account "blizzard" has 3 "users"
    And I am a user of account "blizzard"
    And I send and accept JSON
    And I use my auth token
    When I send a GET request to "/accounts"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error

  Scenario: Anonymous attempts to retrieve all accounts
    Given there exists an account "bungie"
    And I send and accept JSON
    When I send a GET request to "/accounts"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
