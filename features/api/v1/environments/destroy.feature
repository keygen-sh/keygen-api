@api/v1
@ee
Feature: Delete environments
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
    And the current account has 1 "environment"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "403"

  Scenario: Admin deletes an environment
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$2"
    Then the response status should be "204"
    And the current account should have 2 "environments"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete an environment for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes an environment
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$2"
    Then the response status should be "204"
    And the current account should have 2 "environments"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to delete an environment
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$2"
    Then the response status should be "403"
    And the current account should have 3 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to delete an environment
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$2"
    Then the response status should be "403"
    And the current account should have 3 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only attempts to delete an environment
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$2"
    Then the response status should be "403"
    And the current account should have 3 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Environment attempts to delete an environment
    Given the current account is "test1"
    And the current account has 1 isolated "environments"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "403"
    And the current account should have 1 "environment"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete an environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "404"
    And the current account should have 2 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete an environment (no environment)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "404"
    And the current account should have 2 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete an environment (in environment)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "404"
    And the current account should have 1 "environment"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete an environment (no environment)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "404"
    And the current account should have 2 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete an environment (in environment)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "404"
    And the current account should have 1 "environment"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to delete an environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    When I send a DELETE request to "/accounts/test1/environments/$0"
    Then the response status should be "401"
    And the current account should have 2 "environments"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
