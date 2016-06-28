@api/v1
Feature: Show account

  Scenario: Admin retrieves their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a GET request to "/accounts/eQ6Xobga"
    Then the response status should be "200"
    And the JSON response should be an "account"

  Scenario: Admin attempts to retrieve another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And I am an admin of account "blizzard"
    And I send and accept JSON
    And I use my auth token
    When I send a GET request to "/accounts/eQ6Xobga"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
