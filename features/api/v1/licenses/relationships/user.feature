@api/v1
Feature: License user relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves the user for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/user"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Product retrieves the user for a license
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/user"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Product retrieves the user for a license of another user
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/user"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the user for a license
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/user"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the user for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/user"
    Then the response status should be "401"
