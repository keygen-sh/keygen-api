@api/v1
Feature: Delete key

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
    And the current account has 2 "keys"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "403"

  Scenario: Admin deletes one of their keys
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "keys"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/keys/$2"
    Then the response status should be "204"
    And the current account should have 2 "keys"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a key for their environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 3 isolated "keys"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "204"
    And the current account should have 2 "keys"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a key for the nil environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 3 shared "keys"
    And the current account has 3 global "keys"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/keys/$5"
    Then the response status should be "403"
    And the current account should have 6 "keys"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete a key for their product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 pooled "policy" for the last "product"
    And the current account has 3 "keys" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "204"
    And the current account should have 2 "keys"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete a key for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 3 "keys"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "keys"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete a key for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "keys"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "keys"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete a key for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "keys"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "keys"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous user attempts to delete a key for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "keys"
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "keys"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete a key for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/keys/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "keys"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
