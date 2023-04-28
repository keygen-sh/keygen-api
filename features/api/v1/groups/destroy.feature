@api/v1
Feature: Delete groups

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
    And the current account has 1 "group"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0"
    Then the response status should be "403"

  Scenario: Admin deletes a group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$2"
    Then the response status should be "204"
    And the current account should have 2 "groups"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes a group (should nullify user groups)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And the current account has 4 "users" for the second "group"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$1"
    Then the response status should be "204"
    And the current account should have 2 "groups"
    And the current account should have 4 "users"

  Scenario: Admin deletes a group (should nullify license groups)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And the current account has 4 "licenses" for the last "group"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$2"
    Then the response status should be "204"
    And the current account should have 2 "groups"
    And the current account should have 4 "licenses"

  Scenario: Admin deletes a group (should nullify machine groups)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And the current account has 4 "machines" for the first "group"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0"
    Then the response status should be "204"
    And the current account should have 2 "groups"
    And the current account should have 4 "machines"

  Scenario: Admin attempts to delete a group for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes a group
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$2"
    Then the response status should be "204"
    And the current account should have 2 "groups"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$2"
    Then the response status should be "403"
    And the current account should have 3 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$2"
    Then the response status should be "403"
    And the current account should have 3 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$2"
    Then the response status should be "403"
    And the current account should have 3 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 2 isolated "groups"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/groups/$0"
    Then the response status should be "204"
    And the current account should have 1 "group"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0"
    Then the response status should be "204"
    And the current account should have 1 "group"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0"
    Then the response status should be "403"
    And the current account should have 2 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0"
    Then the response status should be "403"
    And the current account should have 2 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to delete a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    When I send a DELETE request to "/accounts/test1/groups/$0"
    Then the response status should be "401"
    And the current account should have 2 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
