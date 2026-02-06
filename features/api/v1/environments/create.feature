@api/v1
@ee
Feature: Create environments
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
    When I send a POST request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: Admin creates an environment for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "Test Environment",
            "code": "test"
          },
          "relationships": {
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "admin@isolated.example",
                    "password": "$ecr3t"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "environment" with the following attributes:
      """
      {
        "isolationStrategy": "ISOLATED",
        "name": "Test Environment",
        "code": "test"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an isolated environment for their account (with admin)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "isolationStrategy": "ISOLATED",
            "name": "Isolated Environment",
            "code": "ISOLATED"
          },
          "relationships": {
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "admin@isolated.example",
                    "password": "$ecr3t"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "environment" with the following attributes:
      """
      {
        "isolationStrategy": "ISOLATED",
        "name": "Isolated Environment",
        "code": "ISOLATED"
      }
      """
    And the current account should have 2 "admins"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an isolated environment for their account (no admin)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "isolationStrategy": "ISOLATED",
            "name": "Isolated Environment",
            "code": "ISOLATED"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "environment" with the following attributes:
      """
      {
        "isolationStrategy": "ISOLATED",
        "name": "Isolated Environment",
        "code": "ISOLATED"
      }
      """
    And the current account should have 1 "admin"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a shared environment for their account (with admins)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Shared Environment",
            "code": "SHARED"
          },
          "relationships": {
            "admins": {
              "data": [
                {
                  "type": "users",
                  "attributes": {
                    "email": "admin@shared.example",
                    "password": "$ecr3t"
                  }
                },
                {
                  "type": "users",
                  "attributes": {
                    "email": "dev@shared.example"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "environment" with the following attributes:
      """
      {
        "isolationStrategy": "SHARED",
        "name": "Shared Environment",
        "code": "SHARED"
      }
      """
    And the current account should have 3 "admins"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a shared environment for their account (no admin)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Shared Environment",
            "code": "SHARED"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "environment" with the following attributes:
      """
      {
        "isolationStrategy": "SHARED",
        "name": "Shared Environment",
        "code": "SHARED"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an incomplete environment for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environment",
          "attributes": {
            "name": "CI/CD"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an environment for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "Production",
            "code": "production"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates an environment for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Development",
            "code": "development"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to create an environment for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Oops",
            "code": "oops"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to create an environment for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "QA",
            "code": "qa"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Environment attempts to create an environment for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environment",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Other",
            "code": "other"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create an environment for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environment",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "App",
            "code": "app"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create an environment for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environment",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Hacker",
            "code": "hax"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to create an environment for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environment",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "CLI",
            "code": "cli"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create an environment for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environment",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Oof",
            "code": "oof"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  # product-specific webhook smoke tests
  Scenario: Admin creates an environment and generates authorized webhooks
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "webhook-endpoints" for each "product"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I authenticate with a token
    When I send a POST request to "/accounts/test1/environments" with the following:
      """
      {
        "data": {
          "type": "environment",
          "attributes": {
            "isolationStrategy": "SHARED",
            "name": "Staging",
            "code": "staging"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
