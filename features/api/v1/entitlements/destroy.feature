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
    And the response body should be an array of 1 error
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

  Scenario: Read-only attempts to delete an entitlement
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$2"
    Then the response status should be "403"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes an isolated entitlement (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 2 isolated "entitlements"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And the current account should have 1 "entitlement"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes a shared entitlement (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 2 shared "entitlements"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 1 "entitlement"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes a global entitlement (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "entitlement"
    And the current account has 1 global "entitlement"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/entitlements/$1"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
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

  Scenario: License attempts to delete an entitlement (does not have entitlement)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "entitlements"
    And the current account has 2 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "404"
    And the current account should have 2 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete an entitlement (does have entitlement)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "license-entitlements" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "403"
    And the current account should have 4 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete an entitlement (does not have entitlement)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "entitlements"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "404"
    And the current account should have 2 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete an entitlement (does have entitlement)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And the current account has 3 "policy-entitlement" for the last "policy"
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 1 "license-entitlement" for each "license"
    And all "licenses" belong to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "403"
    And the current account should have 5 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to delete an entitlement
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "entitlements"
    When I send a DELETE request to "/accounts/test1/entitlements/$0"
    Then the response status should be "401"
    And the current account should have 2 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
