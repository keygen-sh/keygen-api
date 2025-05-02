@api/v1
Feature: Account settings
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1/settings"
    Then the response status should not be "403"

  Scenario: Admin creates a default license permission account setting
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/settings" with the following:
      """
      {
        "data": {
          "type": "settings",
          "attributes": {
            "key": "default_license_permissions",
            "value": [
              "product.read",
              "policy.read",
              "license.read",
              "license.validate",
              "machine.read",
              "machine.create"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "setting" with the following attributes:
      """
      {
        "key": "default_license_permissions",
        "value": [
          "product.read",
          "policy.read",
          "license.read",
          "license.validate",
          "machine.read",
          "machine.create"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 1 "event-log" job

  Scenario: Admin creates a default user permission account setting
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/settings" with the following:
      """
      {
        "data": {
          "type": "settings",
          "attributes": {
            "key": "defaultUserPermissions",
            "value": [
              "user.read",
              "license.read",
              "license.validate",
              "machine.read",
              "machine.create"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "setting" with the following attributes:
      """
      {
        "key": "default_user_permissions",
        "value": [
          "user.read",
          "license.read",
          "license.validate",
          "machine.read",
          "machine.create"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 1 "event-log" job

  Scenario: Admin creates an invalid default user permission account setting
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/settings" with the following:
      """
      {
        "data": {
          "type": "settings",
          "attributes": {
            "key": "defaultUserPermissions",
            "value": {
              "user.read": true
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid setting",
        "code": "VALUE_NOT_ALLOWED"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin creates an invalid account setting
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/settings" with the following:
      """
      {
        "data": {
          "type": "settings",
          "attributes": {
            "key": "foo",
            "value": "bar"
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 2 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be one of: default_license_permissions, default_user_permissions",
        "code": "KEY_NOT_ALLOWED"
      }
      """
     And the second error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid setting",
        "code": "VALUE_NOT_ALLOWED"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin lists their account settings
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_license_permissions",
        "value": [
          "license.validate",
          "license.read"
        ]
      }
      """
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_user_permissions",
        "value": [
          "license.validate",
          "license.read",
          "user.read"
        ]
      }
      """
    When I send a GET request to "/accounts/test1/settings"
    Then the response status should be "200"
    And the response body should be an array of 2 "settings"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin retrieves an account setting
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_license_permissions",
        "value": [
          "license.validate",
          "license.read"
        ]
      }
      """
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_user_permissions",
        "value": [
          "license.validate",
          "license.read",
          "user.read"
        ]
      }
      """
    When I send a GET request to "/accounts/test1/settings/$1"
    Then the response status should be "200"
    And the response body should be a "setting" with the following attributes:
      """
      {
        "key": "default_user_permissions",
        "value": [
          "license.validate",
          "license.read",
          "user.read"
        ]
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 0 "event-log" jobs

  Scenario: Admin updates an account setting
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_license_permissions",
        "value": [
          "license.validate",
          "license.read"
        ]
      }
      """
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_user_permissions",
        "value": [
          "license.validate",
          "license.read",
          "user.read"
        ]
      }
      """
    When I send a PATCH request to "/accounts/test1/settings/$0" with the following:
      """
      {
        "data": {
          "type": "settings",
          "attributes": {
            "value": ["license.validate"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "setting" with the following attributes:
      """
      { "value": ["license.validate"] }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 1 "event-log" job

  Scenario: Admin deletes an account setting
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_license_permissions",
        "value": [
          "license.validate",
          "license.read"
        ]
      }
      """
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_user_permissions",
        "value": [
          "license.validate",
          "license.read",
          "user.read"
        ]
      }
      """
    When I send a DELETE request to "/accounts/test1/settings/$1"
    Then the response status should be "204"
    And the current account should have 1 "setting"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "request-log" jobs
    And sidekiq should have 1 "event-log" job
