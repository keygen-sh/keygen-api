@api/v1
Feature: Create groups

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
    When I send a POST request to "/accounts/test1/groups"
    Then the response status should be "403"

  Scenario: Admin creates a group for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Test Group",
            "maxUsers": 10,
            "maxLicenses": 10,
            "maxMachines": 10,
            "metadata": {
              "foo": "bar"
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "group" with the following attributes:
      """
      {
        "name": "Test Group",
        "maxUsers": 10,
        "maxLicenses": 10,
        "maxMachines": 10,
        "metadata": {
          "foo": "bar"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a minimal group for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "group",
          "attributes": {
            "name": "ACME"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an incomplete group for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "group",
          "attributes": {
            "metadata": {}
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a group for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Space X"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a group for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Some Group"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to create a group for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Sales Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to create a group for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Support Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only attempts to create a group for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Support Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to create a group for their environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "group",
          "attributes": {
            "name": "Isolated Group"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "group" with the following attributes:
      """
      { "name": "Isolated Group" }
      """
    And the response body should be a "group" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create a group for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "group",
          "attributes": {
            "name": "Product Group"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create a group for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "group",
          "attributes": {
            "name": "Product Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to create a group for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "group",
          "attributes": {
            "name": "License Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a group for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/groups" with the following:
      """
      {
        "data": {
          "type": "group",
          "attributes": {
            "name": "Anon Group"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
