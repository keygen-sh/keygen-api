@api/v1
Feature: Password reset

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/passwords"
    Then the response status should not be "403"

  Scenario: User resets their password (has password)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      {
        "meta": {
          "email": "$users[1].email"
        }
      }
      """
    Then the response status should be "204"
    And the user should receive a "password reset" email
    And sidekiq should have 1 "webhook" job

  Scenario: User resets their password (no password)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    And all "users" have the following attributes:
      """
      { "passwordDigest": null }
      """
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      {
        "meta": {
          "email": "$users[1].email"
        }
      }
      """
    Then the response status should be "204"
    And the user should receive a "password reset" email
    And sidekiq should have 1 "webhook" job

  Scenario: User resets their password with case insensitivity
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    And the first "user" has the following attributes:
      """
      { "email": "test@keygen.example" }
      """
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      {
        "meta": {
          "email": "Test@KeyGen.example"
        }
      }
      """
    Then the response status should be "204"
    And the user should receive a "password reset" email
    And sidekiq should have 1 "webhook" job

  Scenario: User resets their password without delivering an email
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      {
        "meta": {
          "email": "$users[1].email",
          "deliver": false
        }
      }
      """
    Then the response status should be "204"
    And the user should not receive a "password reset" email
    And sidekiq should have 1 "webhook" job

  Scenario: User resets their password using a bad email
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      {
        "meta": {
          "email": "bad@email.com"
        }
      }
      """
    Then the response status should be "204"
    And the user should not receive a "password reset" email
    And sidekiq should have 0 "webhook" jobs

  Scenario: User resets their password without an email
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    When I send a POST request to "/accounts/test1/passwords" with the following:
      """
      {
        "meta": {}
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
