@api/v1
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

  Scenario: Admin retrieves the billing info for their account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "200"
    And the JSON response should be a "billing"
    And sidekiq should have 0 "log" jobs

  Scenario: Product attempts to retrieve the billing info for their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin attempts to retrieve the billing info for another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "401"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin updates the billing info for their account
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "log" jobs

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "log" jobs

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "log" jobs

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "log" jobs

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "log" jobs

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "log" jobs

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "log" jobs
