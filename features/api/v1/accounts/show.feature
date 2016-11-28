@api/v1
Feature: Show account

  Background:
    Given the following "accounts" exist:
      | Company | Name  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/$0"
    Then the response status should be "200"
    And the JSON response should be an "account"

  Scenario: Admin attempts to retrieve another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve an account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/$0"
    Then the response status should be "403"
