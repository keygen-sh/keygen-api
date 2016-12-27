@api/v1
Feature: User role relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves the role for a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/role"
    Then the response status should be "200"
    And the JSON response should be a "role"

  Scenario: Admin retrieves the role for a user of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/role"
    Then the response status should be "401"

  Scenario: Product retrieves the role for a user of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/role"
    Then the response status should be "200"
    And the JSON response should be a "role"

  Scenario: Product retrieves the role of a user from another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/role"
    Then the response status should be "403"

  Scenario: User attempts to retrieve their role
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/role"
    Then the response status should be "200"
    And the JSON response should be a "role"

  Scenario: User attempts to retrieve the role for another user
    Given the current account is "test1"
    And the current account has 2 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$2/role"
    Then the response status should be "403"
