@api/v1
Feature: Update groups

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
    And the current account has 1 "group"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0"
    Then the response status should be "403"

  Scenario: Admin updates a group for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "group"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0].id",
          "attributes": {
            "maxMachines": 100,
            "metadata": {
              "namespace": "Keygen"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "group" with the following attributes:
      """
      {
        "maxMachines": 100,
        "metadata": {
          "namespace": "Keygen"
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes limits from a group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "group"
    And the last "group" has the following attributes:
      """
      { "maxMachines": 1 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0].id",
          "attributes": {
            "maxMachines": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "group" with the following attributes:
      """
      { "maxMachines": null }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update a group for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the account "test1" has 1 "groups"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Updated Group"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a group for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "groups"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0].id",
          "attributes": {
            "name": "Updated Group"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "group" with the name "Updated Group"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales updates a group for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "groups"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "group",
          "id": "$groups[0].id",
          "attributes": {
            "name": "Sales Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support updates a group for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "groups"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0].id",
          "attributes": {
            "name": "Support Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only updates a group for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "groups"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0].id",
          "attributes": {
            "name": "Support Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to update a group
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 2 isolated "groups"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Isolated Group"
          }
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Product Group"
          }
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "User Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "License Group"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to update a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "groups"
    When I send a PATCH request to "/accounts/test1/groups/$0" with the following:
      """
      {
        "data": {
          "type": "groups",
          "attributes": {
            "name": "Anonymous Group"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
