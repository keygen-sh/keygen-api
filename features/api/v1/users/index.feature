@api/v1
Feature: List users

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "403"

  Scenario: Admin retrieves all users for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "users"

  Scenario: Admin retrieves a paginated list of users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 21 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "users"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/users?page[number]=2&page[size]=5",
        "next": "/v1/accounts/test1/users?page[number]=3&page[size]=5",
        "prev": "/v1/accounts/test1/users?page[number]=1&page[size]=5",
        "first": "/v1/accounts/test1/users?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/users?page[number]=5&page[size]=5",
        "meta": {
          "pages": 5,
          "count": 21
        }
      }
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a paginated list of users with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of users with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of users with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all users without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "users"

  Scenario: Admin retrieves all users with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "users"

  Scenario: Admin retrieves all users with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "users"

  Scenario: Admin retrieves all users with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all users with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves all users scoped to a specific product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the second "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 3 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]", "policyId": "$policies[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]", "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?product=$products[0]"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "users"

 Scenario: Admin retrieves all active users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 9 "users"
    And the current account has 3 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?active=true"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "users"

  Scenario: Admin retrieves all inactive users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 9 "users"
    And the current account has 2 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?active=false"
    Then the response status should be "200"
    And the JSON response should be an array with 7 "users"

  Scenario: Product retrieves all users for their product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 3 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "user"

  Scenario: Product retrieves all users of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 3 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?product=$products[1]"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "users"

  Scenario: Admin attempts to retrieve all users for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all users for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "users"
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
