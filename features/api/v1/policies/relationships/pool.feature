@api/v1
Feature: Policy pool relationship

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
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "403"

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
    And the response body should be an array with 5 "keys"

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
    And the response body should be a "key"

  Scenario: Admin retrieves the pool of an unpooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": false }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "200"
    And the response body should be an empty array

  Scenario: Admin retrieves a key from the pool of an unpooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "usePool": false }
      """
    And the current account has 1 "key"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool/$0"
    Then the response status should be "404"

  @ee
  Scenario: Environment retrieves the pool for an isolated policy
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated+pooled "policy"
    And the current account has 3 isolated "keys" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "keys"

  @ee
  Scenario: Environment retrieves the pool for a shared policy
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared+pooled "policy"
    And the current account has 3 shared "keys" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 3 "keys"

  @ee
  Scenario: Environment retrieves the pool for a global policy
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global+pooled "policy"
    And the current account has 3 shared "keys" for the last "policy"
    And the current account has 2 global "keys" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 5 "keys"

  Scenario: Product retrieves the pool for a policy
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      {
        "productId": "$products[0]",
        "usePool": true
      }
      """
    And the current account has 5 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I am a product of account "test1"
    And the current product has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "200"
    And the response body should be an array with 5 "keys"

  Scenario: Product retrieves the pool for a policy of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      {
        "productId": "$products[1]",
        "usePool": true
      }
      """
    And the current account has 3 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the pool for a policy
    Given the current account is "test1"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 3 "keys"
    And all "keys" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "404"

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
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "404"

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
    And the current account has 2 "webhook-endpoints"
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
    And the response body should be a "key"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment pops a key from an isolated policy's pool
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated+pooled "policy"
    And the current account has 3 isolated "keys" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "key"

  @ee
  Scenario: Environment pops a key from a shared policy's pool
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared+pooled "policy"
    And the current account has 3 shared "keys" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool?environment=shared"
    Then the response status should be "200"
    And the response body should be a "key"

  @ee
  Scenario: Environment pops a shared key from a global policy's pool
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global+pooled "policy"
    And the current account has 3 shared "keys" for the last "policy"
    And the current account has 2 global "keys" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool?environment=shared"
    Then the response status should be "200"
    And the response body should be a "key"

  # FIXME(ezekg) This probably shouldn't be allowed, but it's such a rarely used feature
  #              that our time would probably be better spent fully deprecating it.
  @ee
  Scenario: Environment pops a global key from a global policy's pool
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global+pooled "policy"
    And the current account has 2 global "keys" for the last "policy"
    And the current account has 3 shared "keys" for the last "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool?environment=shared"
    Then the response status should be "200"
    And the response body should be a "key"

  Scenario: Product pops a key from a pool
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      {
        "productId": "$products[0]",
        "usePool": true
      }
      """
    And the current account has 5 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I am a product of account "test1"
    And the current product has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "200"
    And the response body should be a "key"
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to pop a key from a pool for a policy of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      {
        "productId": "$products[1]",
        "usePool": true
      }
      """
    And the current account has 3 "keys"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "404"

  Scenario: License attempts to pop a key from a pool for a policy
    Given the current account is "test1"
    And the current account has 3 "policies"
    And the current account has 3 "keys"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0/pool"
    Then the response status should be "403"

  Scenario: User attempts to pop a key from a pool for a policy
    Given the current account is "test1"
    And the current account has 3 "policies"
    And the current account has 3 "keys"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user"
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
