@api/v1
Feature: List users

  Background:
    Given the following "accounts" exist:
      | Company | Name  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves all users for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/users"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "users"

  Scenario: Admin retrieves a paginated list of users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "users"

  Scenario: Admin retrieves a paginated list of users with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of users with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of users with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all users without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "users"

  Scenario: Admin retrieves all users with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a GET request to "/users?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "users"

  Scenario: Admin retrieves all users with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "users"

  Scenario: Admin retrieves all users with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all users with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/users?limit=-10"
    Then the response status should be "400"

  Scenario: Product retrieves all users for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "users"
    And the current product has 1 "user"
    When I send a GET request to "/users"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "user"

  Scenario: Admin attempts to retrieve all users for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/users"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all users for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "users"
    When I send a GET request to "/users"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
