@api/v1
Feature: Delete account

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin deletes their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/$0"
    Then the response status should be "204"

  Scenario: Admin attempts to delete another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a DELETE request to "/accounts/$0"
    Then the response status should be "401"

  Scenario: User attempts to delete an account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/$0"
    Then the response status should be "403"
