@api/v1
Feature: Product policies relationship
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
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "403"

  Scenario: Admin retrieves the policies for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "200"
    And the response body should be an array with 3 "policies"

  @ee
  Scenario: Environment retrieves the policies for an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And the current account has 3 isolated "policies" for the last "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "policies"

  @ee
  Scenario: Environment retrieves the policies for a global product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "product"
    And the current account has 3 shared "policies" for the last "product"
    And the current account has 3 global "policies" for the last "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "policies"

  Scenario: Product retrieves the policies for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "200"
    And the response body should be an array with 3 "policies"

  Scenario: Admin retrieves a policy for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy"

  Scenario: Product retrieves a policy for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy"

  Scenario: Product retrieves the policies of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/policies"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the policies for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the policies for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the policies for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the policies for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the policies for a product of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "401"
