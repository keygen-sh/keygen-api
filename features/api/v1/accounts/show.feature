@api/v1
Feature: Show account

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1"
    Then the response status should not be "403"

  Scenario: Admin retrieves their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    And the JSON response should be an "account"

  Scenario: Admin attempts to retrieve another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve an account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "403"

  Scenario: User attempts to retrieve an invalid account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/invalid"
    Then the response status should be "404"
