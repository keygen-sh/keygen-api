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
    And the response body should be a "entitlement"

  Scenario: Developer retrieves an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: Sales retrieves an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: Support retrieves an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: Read-only retrieves an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

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
        "detail": "The requested entitlement 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve an entitlement for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ce
  Scenario: Environment retrieves an entitlement (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "entitlement"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves an entitlement (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "entitlement"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be an "entitlement"

  @ee
  Scenario: Environment retrieves an entitlement (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "entitlement"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be an "entitlement"

  Scenario: Product retrieves an entitlement
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: License retrieves an entitlement (does not have entitlement)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "404"

  Scenario: License retrieves an entitlement (does have entitlement)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "license-entitlements" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be an "entitlement"

  Scenario: User retrieves an entitlement (does not have entitlement)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "404"

  Scenario: User retrieves an entitlement (does have entitlement)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And the current account has 3 "policy-entitlement" for the last "policy"
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 1 "license-entitlement" for each "license"
    And all "licenses" belong to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements/$0"
    Then the response status should be "200"
    And the response body should be an "entitlement"
