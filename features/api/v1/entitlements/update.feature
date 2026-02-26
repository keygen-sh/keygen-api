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
    And the response body should be an "entitlement" with the following attributes:
      """
      {
        "code": "NEW_FEATURE",
        "metadata": {
          "fooBar": "baz-qux"
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
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
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "cannot be blank",
        "source": {
          "pointer": "/data/attributes/code"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
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
    And sidekiq should have 0 "event-log" jobs
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
    And the response body should be an "entitlement" with the name "Updated Feature"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
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
    And sidekiq should have 0 "event-log" jobs
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only updates an entitlement for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates an isolated entitlement (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 2 isolated "entitlements"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Isolated Entitlement"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "entitlement" with the following attributes:
      """
      { "name": "Isolated Entitlement" }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a shared entitlement (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 2 shared "entitlements"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/entitlements/$0" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Shared Entitlement"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "entitlement" with the following attributes:
      """
      { "name": "Shared Entitlement" }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a global entitlement (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "entitlement"
    And the current account has 1 global "entitlement"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/entitlements/$1" with the following:
      """
      {
        "data": {
          "type": "entitlements",
          "attributes": {
            "name": "Global Entitlement"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
