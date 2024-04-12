@api/v1
Feature: Delete policy

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
    When I send a DELETE request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their policies
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "204"
    And the current account should have 2 "policies"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes one of their policies
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "204"
    And the current account should have 2 "policies"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales deletes one of their policies
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "403"

  Scenario: Support deletes one of their policies
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "403"

  Scenario: Read-only deletes one of their policies
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "403"

  Scenario: Admin attempts to delete a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "policies"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes an isolated policy
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 3 isolated "policies"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2?environment=isolated"
    Then the response status should be "204"
    And the current account should have 2 "policies"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes a shared policy
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 3 shared "policies"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$1?environment=shared"
    Then the response status should be "204"
    And the current account should have 2 "policies"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes a global policy
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 3 global "policies"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0?environment=shared"
    Then the response status should be "403"
    And the current account should have 3 "policies"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes one of their policies
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies" for the first "product"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "204"
    And the current account should have 2 "policies"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes a policy for a different product
    Given the current account is "test1"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies" for the second "product"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "404"
    And the current account should have 3 "policies"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete a policy for their product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: User attempts to delete a policy for their product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: Anonymous attempts to delete a policy
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "policies"
    When I send a DELETE request to "/accounts/test1/policies/$2"
    Then the response status should be "401"
