@api/v1
Feature: Update account
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1"
    Then the response status should not be "403"

  Scenario: Admin updates their account
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "id": "$accounts[0].id",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "account" with the name "Company Name"
    And the response body should be an "account" with the following meta:
      """
      {
        "publicKey": "$~accounts[0].public_key",
        "keys": {
          "ed25519": "$~accounts[0].ed25519_public_key",
          "rsa2048": "$~accounts[0].public_key"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Isolated admin updates their account
    Given the account "test1" has 1 isolated "webhook-endpoint"
    And the account "test1" has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Isolated Account"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Shared admin updates their account
    Given the account "test1" has 1 shared "webhook-endpoint"
    And the account "test1" has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Shared Account"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin updates the name for their account
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "new-name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "account" with the slug "new-name"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin updates their account's API version to v1.0
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "apiVersion": "1.0"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "account" with the following attributes:
      """
      { "apiVersion": "1.0" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin updates their account's API version to v1.1
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "apiVersion": "1.1"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "account" with the following attributes:
      """
      { "apiVersion": "1.1" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin updates their account's API version to v1.2
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "apiVersion": "1.2"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an "account" with the following attributes:
      """
      { "apiVersion": "1.2" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin updates their account's API version an an invalid version
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "apiVersion": "0.0"
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
        "detail": "is invalid",
        "source": {
          "pointer": "/data/attributes/apiVersion"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to update another account
    Given I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ce
  Scenario: Environment attempts to update an account (isolated)
    Given the account "test1" has 1 isolated "environment"
    And the account "test1" has 1 "webhook-endpoint"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "hax"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to update an account (isolated)
    Given the account "test1" has 1 isolated "environment"
    And the account "test1" has 1 "webhook-endpoint"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "hax"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to update an account (shared)
    Given the account "test1" has 1 shared "environment"
    And the account "test1" has 1 "webhook-endpoint"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "hax"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to update an account (global)
    Given the account "test1" has 1 isolated "environment"
    And the account "test1" has 1 "webhook-endpoint"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "hax"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to update an account
    Given the account "test1" has 1 "product"
    And the account "test1" has 1 "webhook-endpoint"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "hax"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to update an account
    Given the account "test1" has 1 "user"
    And the account "test1" has 1 "webhook-endpoint"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs
