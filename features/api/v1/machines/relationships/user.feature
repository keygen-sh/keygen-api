@api/v1
Feature: Machine user relationship

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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "403"

  Scenario: Admin retrieves the user for a machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "200"
    And the JSON response should be a "user"
    And the response should contain a valid signature header for "test1"

  Scenario: Product retrieves the user for a machine
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Product retrieves the user for a machine of another product
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[2]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the user for a machine they own
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: User attempts to retrieve the user for a machine they don't own
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "404"

  Scenario: License attempst to retrieve their user
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the first "user"
    And the current account has 1 "license" for the second "user"
    And the current account has 2 "machines" for the first "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the user for a different license
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the first "user"
    And the current account has 1 "license" for the second "user"
    And the current account has 2 "machines" for the second "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$1/user"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the user for a machine of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/user"
    Then the response status should be "401"
