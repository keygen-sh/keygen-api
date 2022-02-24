@api/v1
Feature: User tokens relationship

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
    When I send a GET request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin generates an admin token (themself)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin generates an admin token (another)
    Given the current account is "test1"
    And the current account has 1 "admin"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "403"

  Scenario: Admin generates a user token (has password)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now"
    And the JSON response should be a "token" with the kind "user-token"
    And the JSON response should be a "token" with a token
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a user token (no password)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "passwordDigest": null }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now"
    And the JSON response should be a "token" with the kind "user-token"
    And the JSON response should be a "token" with a token
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a user token with a custom expiry (present)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "expiry": "2016-10-05T22:53:37.000Z"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a user token with a custom expiry (null)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "expiry": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now"
    And the JSON response should be a "token" with the kind "user-token"
    And the JSON response should be a "token" with a token
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "403"

  Scenario: User generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "403"

  Scenario: Anonymous generates a user token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "401"

  Scenario: Admin requests tokens for one of their users
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 5 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$3/tokens"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests tokens for one of their users
    Given the current account is "test1"
    And the current account has 5 "products"
    And I am a product of account "test1"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"

  Scenario: Product requests tokens for another product's user
    Given the current account is "test1"
    And the current account has 5 "products"
    And I am a product of account "test1"
    And the current account has 5 "users"
    And the current product has 2 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$5/tokens"
    Then the response status should be "200"

  Scenario: User requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 6 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: User requests tokens for another user
    Given the current account is "test1"
    And the current account has 4 "products"
    And the current account has 6 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/tokens"
    Then the response status should be "403"

  Scenario: User requests their tokens without authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a GET request to "/accounts/test1/users/$1/tokens"
    Then the response status should be "401"
