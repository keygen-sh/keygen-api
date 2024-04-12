@api/v1
Feature: Policy product relationship

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
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "403"

  Scenario: Admin retrieves the product for a policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "200"
    And the response body should be a "product"

  @ee
  Scenario: Environment retrieves the product for an isolated policy
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Product retrieves the product for a policy
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Product retrieves the product for a policy of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the product for their policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the product for a policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the product for their policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the product for a policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the product for a policy of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/product"
    Then the response status should be "401"
