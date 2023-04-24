@api/v1
Feature: Delete account
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a DELETE request to "/accounts/test1"
    Then the response status should not be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin deletes their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1"
    Then the response status should be "403"

  @mp
  Scenario: Admin attempts to delete another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1"
    Then the response status should be "401"
    And sidekiq should have 0 "request-log" jobs

  @sp
  Scenario: Admin attempts to delete another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to delete an account
    Given the account "test1" has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1"
    Then the response status should be "403"

  Scenario: Product attempts to delete an account
    Given the account "test1" has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1"
    Then the response status should be "403"

  Scenario: User attempts to delete an account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1"
    Then the response status should be "403"
