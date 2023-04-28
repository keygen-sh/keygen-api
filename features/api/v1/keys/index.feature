@api/v1
Feature: List keys

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
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "403"

  Scenario: Admin retrieves all keys for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "200"
    And the response body should be an array with 3 "keys"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves a paginated list of keys
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "keys"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves a paginated list of keys with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?page[number]=1&page[size]=250"
    Then the response status should be "400"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves a paginated list of keys with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?page[number]=1&page[size]=-250"
    Then the response status should be "400"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves a paginated list of keys with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?page[number]=-1&page[size]=10"
    Then the response status should be "400"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves all keys without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "200"
    And the response body should be an array with 10 "keys"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves all keys with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "keys"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves all keys with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "keys"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves all keys with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?limit=900"
    Then the response status should be "400"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves all keys with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys?limit=-900"
    Then the response status should be "400"
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to retrieve all isolated keys (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "keys"
    And the current account has 3 shared "keys"
    And the current account has 3 global "keys"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "200"
    And the response body should be an array with 3 "keys"
    And the response body should be an array of 3 "keys" with the following relationships:
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

  @ee
  Scenario: Environment attempts to retrieve all shared keys (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "keys"
    And the current account has 3 shared "keys"
    And the current account has 3 global "keys"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "200"
    And the response body should be an array with 6 "keys"
    And the response body should be an array of 3 "keys" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be an array of 3 "keys" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  Scenario: Product retrieves all keys for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "keys"
    And the current product has 1 "key"
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "200"
    And the response body should be an array with 1 "key"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to retrieve all keys for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve all keys for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 3 "keys"
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve all keys for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "keys"
    When I send a GET request to "/accounts/test1/keys"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 1 "request-log" job
