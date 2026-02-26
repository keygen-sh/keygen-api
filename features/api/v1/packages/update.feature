@api/v1
Feature: Update package
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
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0"
    Then the response status should be "403"

  Scenario: Admin updates the engine of a package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "engine": "pypi"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      { "engine": "pypi" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes the engine of a package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 pypi "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "engine": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      { "engine": null }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the name of a package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0].id",
          "attributes": {
            "name": "TypedParams"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      { "name": "TypedParams" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the key of a package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "key": "typed_params"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      { "key": "typed_params" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the metadata of a package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0].id",
          "attributes": {
            "metadata": {
              "requiresPython": "<3.0.0"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      {
        "metadata": {
          "requiresPython": "<3.0.0"
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update a package for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the account "test1" has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Updated App"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a package for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0].id",
          "attributes": {
            "name": "Dev Package"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      { "name": "Dev Package" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales updates a package for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0].id",
          "attributes": {
            "name": "Sales Package"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support updates a package for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0].id",
          "attributes": {
            "name": "Support Package"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only updates a package for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "package"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0].id",
          "attributes": {
            "name": "Bad Package"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates an isolated package
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "package"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Isolated Package"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      { "name": "Isolated Package" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a shared package
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 shared "package"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Shared Package"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      { "name": "Shared Package" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a global package
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 global "package"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Global Package"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates the metadata for its package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "packages"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "metadata": {
              "requiresPython": ">=3.0.0"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following attributes:
      """
      {
        "metadata": {
          "requiresPython": ">=3.0.0"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a package for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "packages"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$1" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "key": "nope"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update a package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Oof"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update a package for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "package"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Oof"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Oof"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a package for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "package"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Oof"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonyous attempts to update a package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "package"
    When I send a PATCH request to "/accounts/test1/packages/$0" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Oof"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
