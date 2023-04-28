@api/v1
Feature: Product users relationship

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
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "403"

  Scenario: Admin retrieves the users for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 3 "users"
    And the current account has 4 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]", "policyId": "$policies[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]", "policyId": "$policies[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  @ee
  Scenario: Environment retrieves the users for an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 isolated "policy" for the last "product"
    And the current account has 3 isolated+user "licenses" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  @ee
  Scenario: Environment retrieves the users for a global product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "product"
    And the current account has 1 global "policy" for the last "product"
    And the current account has 1 global+user "license" for the last "policy"
    And the current account has 1 shared+user "license" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "users"

  Scenario: Product retrieves the users for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
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
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]", "policyId": "$policies[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Admin retrieves a user for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users/$1"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: Product retrieves a user for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users/$1"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: Product retrieves the users of another product
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
    When I send a GET request to "/accounts/test1/products/$1/users"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the users for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the users for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the users for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the users for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the users for a product of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/users"
    Then the response status should be "401"
