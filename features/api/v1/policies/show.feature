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

  Scenario: Admin retrieves a policy for their account with correct relationship data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 122 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 9 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the JSON response should be a "policy" with the following relationships:
      """
      {
        "pool": {
          "links": { "related": "/v1/accounts/$accounts[0]/policies/$policies[0]/pool" },
          "meta": { "count": 122 }
        },
        "licenses": {
          "links": { "related": "/v1/accounts/$accounts[0]/policies/$policies[0]/licenses" },
          "meta": { "count": 9 }
        }
      }
      """

  Scenario: Admin retrieves an invalid policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/invalid"
    Then the response status should be "404"

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
