@api/v1
Feature: User licenses relationship
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
    When I send a GET request to "/accounts/test1/users/$0/licenses"
    Then the response status should be "403"

  Scenario: Admin retrieves the licenses for a user
    Given I am an admin of account "test1"
    And the current account is "test1"
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
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/licenses"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an array with 3 "licenses"

  @ee
  Scenario: Environment retrieves the licenses for an isolated user
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "user"
    And the current account has 3 isolated "licenses" for the last "user" as "owner"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/licenses?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: Product retrieves the licenses for a user
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
    When I send a GET request to "/accounts/test1/users/$1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: Admin retrieves a license for a user
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
    When I send a GET request to "/accounts/test1/users/$1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: Product retrieves a license for a user
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
    When I send a GET request to "/accounts/test1/users/$1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: Product retrieves the licenses of a user from another product
    Given the current account is "test1"
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
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/licenses"
    Then the response status should be "200"
    And the response body should be an array of 1 "license"

  Scenario: License attempts to retrieve the licenses for another user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "users"
    And the current account has 1 "license" for each "user" through "owner"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$2/licenses"
    Then the response status should be "404"

  Scenario: License attempts to retrieve their user's licenses
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/licenses"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the licenses for another user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "users"
    And the current account has 1 "license" for each "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$2/licenses"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the licenses for an associated user
    Given the current account is "test1"
    And the current account has 3 "users"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the first "user"
    And the current account has 1 "license-user" for the last "license" and the second "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/licenses"
    Then the response status should be "403"

  Scenario: User attempts to retrieve their licenses
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user"
    And the current account has 2 "license" for the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Anonymous attempts to retrieve licenses for a user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 2 "users"
    And the current account has 5 "licenses"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[2]", "policyId": "$policies[0]" }
      """
    When I send a GET request to "/accounts/test1/users/$2/licenses"
    Then the response status should be "401"

  Scenario: Admin attempts to retrieve the licenses for a user of another account
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
    When I send a GET request to "/accounts/test1/users/$1/licenses"
    Then the response status should be "401"
