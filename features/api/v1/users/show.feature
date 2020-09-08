@api/v1
Feature: Show user

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0"
    Then the response status should not be "403"

  Scenario: Admin retrieves a user for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "user"

  Scenario: Developer retrieves a user for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$3"
    Then the response status should be "200"

  Scenario: Sales retrieves a user for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$3"
    Then the response status should be "200"

  Scenario: Support retrieves a user for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$3"
    Then the response status should be "200"

  Scenario: Admin retrieves a user for their account by email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And the second "user" has the following attributes:
      """
      {
        "email": "user@example.com"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/user@example.com"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "user"
    And the JSON response should be a "user" with the role "user"
    And the JSON response should be a "user" with no meta

  Scenario: Admin retrieves another admin for their account by email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "admins"
    And the first "admin" has the following attributes:
      """
      {
        "email": "user@example.com"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/user@example.com"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "user"
    And the JSON response should be a "user" with the role "admin"
    And the JSON response should be an "user" with the following meta:
      """
      { "intercomId": "$users[0].intercom_id" }
      """

  Scenario: Admin retrieves an invalid user for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested user 'invalid' was not found"
      }
      """

  Scenario: Product retrieves a user for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "user"
    And the current product has 1 "user"
    When I send a GET request to "/accounts/test1/users/$1"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Product retrieves a user for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "user"
    When I send a GET request to "/accounts/test1/users/$1"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: User attempts to retrieve another user
    Given the current account is "test1"
    And the current account has 2 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$2"
    Then the response status should be "403"

  Scenario: User retrieves their profile
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Admin attempts to retrieve a user for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
