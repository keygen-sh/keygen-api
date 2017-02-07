@api/v1
Feature: Policy pool relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves the pool for a policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 5 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "keys"

  Scenario: Admin retrieves a key from the pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 5 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool/$0"
    Then the response status should be "200"
    And the JSON response should be a "key"

  Scenario: Product retrieves the pool for a policy
    Given the current account is "test1"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 5 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "keys"

  Scenario: Product retrieves the pool for a policy of another product
    Given the current account is "test1"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 3 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the pool for a policy
    Given the current account is "test1"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 3 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the pool for a policy of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 3 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "401"

  Scenario: Admin pops a key from a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 1 "key"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "200"
    And the JSON response should be a "key"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin attempts to pop a key from an empty pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to pop a key from a policy that doesn't use a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": false }
      """
    And the current account has 5 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product pops a key from a pool
    Given the current account is "test1"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 5 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "200"
    And the JSON response should be a "key"
    And sidekiq should have 1 "metric" job

  Scenario: Product attempts to pop a key from a pool for a policy of another product
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 3 "keys"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "403"

  Scenario: User attempts to pop a key from a pool for a policy
    Given the current account is "test1"
    And the current account has 3 "policies"
    And the current account has 3 "keys"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "403"

  Scenario: Admin attempts to pop a key from a pool for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the account "test1" has 1 "policy"
    And the account "test1" has 1 "key"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "401"
