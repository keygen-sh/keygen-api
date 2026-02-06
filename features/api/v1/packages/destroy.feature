@api/v1
Feature: Delete package
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
    And the current account has 1 "package"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their packages
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$2"
    Then the response status should be "204"
    And the current account should have 2 "packages"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete a package for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "packages"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes one of their packages
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$2"
    Then the response status should be "204"
    And the current account should have 2 "packages"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to delete one of their packages
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$2"
    Then the response status should be "403"
    And the current account should have 3 "packages"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to delete one of their packages
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$2"
    Then the response status should be "403"
    And the current account should have 3 "packages"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only attempts to delete one of their packages
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$2"
    Then the response status should be "403"
    And the current account should have 3 "packages"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes an isolated package
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "package"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$0?environment=isolated"
    Then the response status should be "204"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes their package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "packages"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$0"
    Then the response status should be "204"
    And the current account should have 1 "package"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes a package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "packages"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$1"
    Then the response status should be "404"
    And the current account should have 3 "packages"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete their package
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$0"
    Then the response status should be "403"

  Scenario: License attempts to delete a package
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$0"
    Then the response status should be "404"

  Scenario: User attempts to delete a one of their packages
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$0"
    Then the response status should be "403"

  Scenario: User attempts to delete a package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "package"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/packages/$0"
    Then the response status should be "404"

  Scenario: Anonymous attempts to delete a package
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "packages"
    When I send a DELETE request to "/accounts/test1/packages/$1"
    Then the response status should be "401"
