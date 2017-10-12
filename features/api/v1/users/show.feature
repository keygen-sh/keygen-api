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
    And the JSON response should be a "user"

  Scenario: Admin retrieves a user for their account with correct relationship data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]", "userId": "$users[0]" }
      """
    And the current account has 4 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0"
    Then the response status should be "200"
    And the JSON response should be a "user" with the following relationships:
      """
      {
        "licenses": {
          "links": { "related": "/v1/accounts/$accounts[0]/users/$users[0]/licenses" },
          "meta": { "count": 2 }
        },
        "machines": {
          "links": { "related": "/v1/accounts/$accounts[0]/users/$users[0]/machines" },
          "meta": { "count": 4 }
        },
        "tokens": {
          "links": { "related": "/v1/accounts/$accounts[0]/users/$users[0]/tokens" },
          "meta": { "count": 1 }
        }
      }
      """

  Scenario: Admin retrieves an invalid user for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/invalid"
    Then the response status should be "404"

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
