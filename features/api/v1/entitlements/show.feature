@api/v1
Feature: Show entitlement

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
    And the current account has 1 "entitlement"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves an entitlement for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: Developer retrieves an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: Sales retrieves an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: Support retrieves an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: Admin retrieves an invalid entitlement for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested entitlement 'invalid' was not found"
      }
      """

  Scenario: Admin attempts to retrieve an entitlement for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: Product retrieves an entitlement
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "403"
