@api/v1
@mp
Feature: Account billing relationship
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should not be "403"

  # Retrieve
  Scenario: Admin retrieves the billing info for their account (not initialized)
    Given the account "test1" has its billing uninitialized
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves the billing info for their account (initialized)
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "200"
    And the response body should be a "billing"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Isolated admin retrieves the billing info for their account
    Given the account "test1" has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing?environment=isolated"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Shared admin retrieves the billing info for their account
    Given the account "test1" has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing?environment=shared"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Developer attempts to retrieve the billing info for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Sales attempts to retrieve the billing info for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Support attempts to retrieve the billing info for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Read-only attempts to retrieve the billing info for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ce
  Scenario: Environment attempts to retrieve the billing info for their account (isolated)
    Given the account "test1" is subscribed
    And the account "test1" has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve the billing info for their account (isolated)
    Given the account "test1" is subscribed
    And the account "test1" has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve the billing info for their account (shared)
    Given the account "test1" is subscribed
    And the account "test1" has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve the billing info for their account (global)
    Given the account "test1" is subscribed
    And the account "test1" has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "401"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to retrieve the billing info for their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to retrieve the billing info for another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "401"
    And sidekiq should have 0 "request-log" jobs

  # Update
  Scenario: Admin updates the billing info for their account (not initialized)
    Given the account "test1" has its billing uninitialized
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin updates the billing info for their account (initialized)
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "202"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Isolated admin updates the billing info for their account
    Given the account "test1" has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing?environment=isolated" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Shared admin updates the billing info for their account
    Given the account "test1" has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing?environment=shared" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to update the billing info for their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to update the billing info for another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin applies a coupon to their account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I have a valid coupon
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "coupon": "COUPON_CODE"
          }
        }
      }
      """
    Then the response status should be "202"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to apply a coupon to their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I have a valid coupon
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "coupon": "COUPON_CODE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to apply a coupon to another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I have a valid coupon
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "coupon": "COUPON_CODE"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin applies an invalid coupon to their account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      {
        "data": {
          "type": "billings",
          "attributes": {
            "coupon": "INVALID_COUPON_CODE"
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs
