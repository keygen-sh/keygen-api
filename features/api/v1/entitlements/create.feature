@api/v1
Feature: Create entitlements

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
    When I send a POST request to "/accounts/test1/entitlements"
    Then the response status should be "403"

  Scenario: Admin creates an entitlement for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Test Entitlement",
            "code": "TEST_ENTITLEMENT"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an incomplete entitlement for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "V1 Updates"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an entitlement for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Cool Feature",
            "code": "COOL_FEATURE"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Cool Feature",
            "code": "COOL_FEATURE"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Sales Feature",
            "code": "SALES_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Support Feature",
            "code": "SUPPORT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/entitlements" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "attributes": {
            "name": "Product Feature",
            "code": "PRODUCT_FEATURE"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
