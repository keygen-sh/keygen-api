@api/v1
Feature: Policy licenses relationship
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
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "403"

  Scenario: Admin retrieves the licenses for a policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  @ee
  Scenario: Environment retrieves the licenses for an isolated policy
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy"
    And the current account has 3 isolated "licenses" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  @ee
  Scenario: Environment retrieves the licenses for a shared policy
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "policy"
    And the current account has 3 shared "licenses" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  @ee
  Scenario: Environment retrieves the licenses for a global policy
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "policy"
    And the current account has 3 shared "licenses" for the last "policy"
    And the current account has 2 global "licenses" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 5 "licenses"

  Scenario: Product retrieves the licenses for a policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: Admin retrieves a license for a policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: Product retrieves a license for a policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: Product retrieves the licenses for a policy of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the licenses for their policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the licenses for a policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "license"
    And the current account has 3 "licenses" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the licenses for their policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the licenses for a policy
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the licenses for a policy of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/licenses"
    Then the response status should be "401"
