@api/v1
Feature: Show policy

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
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Developer retrieves a policy for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"

  Scenario: Sales retrieves a policy for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"

  Scenario: Support retrieves a policy for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves an invalid policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested policy 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Product retrieves a policy for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "policy"
    And the current product has 1 "policy"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Product attempts to retrieve a policy for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "policy"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
