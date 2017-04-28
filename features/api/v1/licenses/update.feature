@api/v1
Feature: Update license

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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin updates a license expiry
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-09-05T22:53:37.000Z"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin updates a license policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 2 "policies"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin updates a license key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product updates a license for their product
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    And the current product has 1 "license"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "b"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs

  Scenario: Product attempts to update a license for another product
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "c"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User attempts to update a license for their account
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 3 "licenses"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "x"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous user attempts to update a license for their account
    Given the current account is "test1"
    And the current account has 5 "webhookEndpoints"
    And the current account has 3 "licenses"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "y"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to update a license for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "z"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin updates a license key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "xyz"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin updates a license expiry
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z",
            "suspended": true
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And the JSON response should be a "license" that is suspended
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product updates a license expiry for their product
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    And the current product has 1 "license"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product attempts to update a license expiry for another product
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User attempts to update a license expiry for their account
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 3 "licenses"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
