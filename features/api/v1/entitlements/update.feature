@api/v1
Feature: Update entitlements

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
    And the current account has 1 "entitlement"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0"
    Then the response status should be "403"

  Scenario: Admin updates an entitlement for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "entitlement"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "id": "$entitlements[0].id",
          "attributes": {
            "code": "NEW_FEATURE",
            "metadata": {
              "foo-bar": "baz-qux"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an "entitlement" with the following attributes:
      """
      {
        "code": "NEW_FEATURE",
        "metadata": {
          "fooBar": "baz-qux"
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an entitlement with an empty code for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "entitlement"
    And the first "entitlement" has the following attributes:
      """
      {
        "code": "EXPL_FEATURE_1"
      }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "id": "$entitlements[0].id",
          "attributes": {
            "code": ""
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update an entitlement for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the account "test1" has 1 "entitlements"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Updated Feature"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "entitlements"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "id": "$entitlements[0].id",
          "attributes": {
            "name": "Updated Feature"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an "entitlement" with the name "Updated Feature"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales updates an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "entitlements"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlement",
          "id": "$entitlements[0].id",
          "attributes": {
            "name": "Sales Entitlement"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support updates an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "entitlements"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "id": "$entitlements[0].id",
          "attributes": {
            "name": "Support Entitlement"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update an entitlement
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "entitlements"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Product Entitlement"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job