@api/v1
@ee
Feature: Update environments
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
    And the current account has 1 "environment"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0"
    Then the response status should be "403"

  Scenario: Admin updates an environment for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environment"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "id": "$environments[0].id",
          "attributes": {
            "code": "test"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "environment" with the following attributes:
      """
      { "code": "test" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an environment with an empty code for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environment"
    And the first "environment" has the following attributes:
      """
      { "code": "production" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "id": "$environments[0].id",
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an environment's isolation strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environment"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "id": "$environments[0].id",
          "attributes": {
            "isolationStrategy": "SHARED"
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
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/isolationStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an environment's admins relationship
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environment"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {},
          "relationships": {
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "admin@environment.example",
                    "password": "$ecr3t"
                  }
                }
              ]
            }
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
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/relationships"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update an environment for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the account "test1" has 1 "environments"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "CI/CD"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates an environment for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environments"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "id": "$environments[0].id",
          "attributes": {
            "name": "Local"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "environment" with the name "Local"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales updates an environment for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environments"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environment",
          "id": "$environments[0].id",
          "attributes": {
            "name": "Leads"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support updates an environment for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environments"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "id": "$environments[0].id",
          "attributes": {
            "name": "QA"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only updates an environment for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "environments"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "id": "$environments[0].id",
          "attributes": {
            "name": "Production"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Environment attempts to updates itself
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "Staging"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Environment attempts to update an environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/environments/$1" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "Staging"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update an environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "App"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update an environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "App"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update an environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "App"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to update an environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "environments"
    When I send a PATCH request to "/accounts/test1/environments/$0" with the following:
      """
      {
        "data": {
          "type": "environments",
          "attributes": {
            "name": "Oof"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
