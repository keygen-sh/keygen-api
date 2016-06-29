@api/v1
Feature: Delete account

  Scenario: Admin deletes their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a DELETE request to "/accounts/eQ6Xobga"
    Then the response status should be "204"

  Scenario: Admin attempts to delete another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And I am an admin of account "blizzard"
    And I send and accept JSON
    And I use my auth token
    When I send a DELETE request to "/accounts/eQ6Xobga"
    Then the response status should be "401"

  Scenario: User attempts to delete an account
    Given there exists an account "bungie"
    And the account "bungie" has 1 "user"
    And I am a user of account "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a DELETE request to "/accounts/eQ6Xobga"
    Then the response status should be "403"
