@api/v1
Feature: Create license

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin creates a license for a user of their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/licenses" with the following:
      """
      { "license": { "policy": "$policies[0]", "user": "$users[0]" } }
      """
    Then the response status should be "201"

  Scenario: Admin creates a license specifying a key
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/licenses" with the following:
      """
      { "license": { "policy": "$policies[0]", "user": "$users[0]", "key": "a" } }
      """
    Then the response status should be "400"

  Scenario: User creates a license for themself
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/licenses" with the following:
      """
      { "license": { "policy": "$policies[0]", "user": "$users[0]" } }
      """
    Then the response status should be "403"

  Scenario: Admin creates a license with the policy license pool
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "usePool": true
      }
      """
    And the current account has 4 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": $policies[0].id
      }
      """
    And the current account has 3 "users"
    And I use my auth token
    When I send a POST request to "/licenses" with the following:
      """
      { "license": { "policy": "$policies[0]", "user": "$users[1]" } }
      """
    Then the response status should be "201"

  Scenario: Admin creates a license with an empty policy license pool
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "usePool": true
      }
      """
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/licenses" with the following:
      """
      { "license": { "policy": "$policies[0]", "user": "$users[0]" } }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 2 errors

  Scenario: Admin creates a license for a user of another account
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/licenses" with the following:
      """
      { "license": { "policy": "$policies[0]", "user": "$users[0]" } }
      """
    Then the response status should be "401"
