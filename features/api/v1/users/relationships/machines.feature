@api/v1
Feature: User machines relationship

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
    When I send a GET request to "/accounts/test1/users/$0/machines"
    Then the response status should be "403"

  Scenario: Admin retrieves the machines for a user
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
    And the current account has 5 "machines"
    And 3 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an array with 3 "machines"

  @ee
  Scenario: Environment retrieves the machines for an isolated user
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "user"
    And the current account has 3 isolated "machines" for the last "user"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: Product retrieves the machines for a user
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
    And the current account has 5 "machines"
    And 3 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: Admin retrieves a machine for a user
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
    And the current account has 5 "machines"
    And 3 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: Product retrieves a machine for a user
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: Product retrieves the machines of a user from another product
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines"
    Then the response status should be "200"
    And the response body should be an empty array

  Scenario: License attempts to retrieve the machines for another user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "users"
    And the current account has 1 "license" for each "user"
    And the current account has 3 "machines" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$2/machines"
    Then the response status should be "404"

  Scenario: License attempts to retrieve their user's machines
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 3 "machines" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the machines for another user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "users"
    And the current account has 1 "license" for each "user"
    And the current account has 3 "machines" for each "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$2/machines"
    Then the response status should be "404"

  Scenario: User attempts to retrieve their machines
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 3 "machines" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: Admin attempts to retrieve the machines for a user of another account
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/machines"
    Then the response status should be "401"
