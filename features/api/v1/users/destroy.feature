@api/v1
Feature: Delete user

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
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["user.created", "user.updated"]
      }
      """
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$3"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "users"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer attempts to delete an admin
    Given the current account is "test1"
    And the current account has 1 "developer"
    And the current account has 3 "admins"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$3"
    Then the response status should be "403"

  Scenario: Developer deletes one of their users
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$3"
    Then the response status should be "204"

  Scenario: Sales attempts to delete one of their users
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$3"
    Then the response status should be "403"

  Scenario: Support attempts to delete one of their users
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$3"
    Then the response status should be "403"

  Scenario: Admin attempts to delete a user for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$3"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "users"

  Scenario: Product attempts to delete one of their users
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$3"
    Then the response status should be "403"
    And the current account should have 3 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete themself
    Given the current account is "test1"
    And the current account has 3 "users"
    And the current account has 1 "webhook-endpoint"
    And I am a user of account "test1"
    And I send and accept JSON
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$current"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete themself when they're not the only admin
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "admin"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$current"
    Then the response status should be "204"
    And the current account should have 1 "admin"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete themself when they're the only admin
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$current"
    Then the response status should be "422"
    And the current account should have 1 "admin"
    And the first error should have the following properties:
      """
        {
          "title": "Unprocessable resource",
          "detail": "account must have at least 1 admin user",
          "source": {
            "pointer": "/data/relationships/account"
          },
          "code": "ACCOUNT_ADMINS_REQUIRED"
        }
      """
