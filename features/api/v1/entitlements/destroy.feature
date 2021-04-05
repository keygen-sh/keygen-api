@api/v1
Feature: Delete entitlements

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
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "403"

  Scenario: Admin deletes an entitlement
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$2"
    Then the response status should be "204"
    And the current account should have 2 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete an entitlement for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes an entitlement
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$2"
    Then the response status should be "204"
    And the current account should have 2 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to delete an entitlement
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$2"
    Then the response status should be "403"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to delete an entitlement
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$2"
    Then the response status should be "403"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete an entitlement
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "entitlements"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "403"
    And the current account should have 2 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
