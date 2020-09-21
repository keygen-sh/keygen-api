@api/v1
Feature: Generate authentication token

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should not be "403"

  Scenario: Admin generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "admin-token",
        "expiry": null
      }
      """
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin with 2FA enabled generates a new token via basic authentication without an OTP code
    Given I am an admin of account "test1"
    And I have 2FA enabled
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
       "title": "Unauthorized",
        "detail": "second factor is required",
        "code": "OTP_REQUIRED",
        "source": {
          "pointer": "/meta/otp"
        }
      }
      """

  Scenario: Admin with 2FA enabled generates a new token via basic authentication with an invalid OTP code
    Given I am an admin of account "test1"
    And I have 2FA enabled
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "meta": {
          "otp": "000000"
        }
      }
      """
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "second factor must be valid",
        "code": "OTP_INVALID",
        "source": {
          "pointer": "/meta/otp"
        }
      }
      """

  Scenario: Admin with 2FA enabled generates a new token via basic authentication with a valid OTP code
    Given I am an admin of account "test1"
    And I have 2FA enabled
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "admin-token"
      }
      """

  Scenario: Developer generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "developer-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "sales-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Support generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "support-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a new token with a custom expiry via basic authentication
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2531-01-01T00:00:00.000Z"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with an expiry "2531-01-01T00:00:00.000Z"
    And the JSON response should be a "token" with the following attributes:
      """
      { "kind": "admin-token" }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with a expiry
    And the JSON response should be a "token" with the following attributes:
      """
      { "kind": "user-token" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token with a custom expiry via basic authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2049-01-01T00:00:00.000Z"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with an expiry "2049-01-01T00:00:00.000Z"
    And the JSON response should be a "token" with the following attributes:
      """
      { "kind": "user-token" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User generates a new token without an expiry via basic authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens" with the following:
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
    Then the response status should be "201"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "user-token",
        "expiry": null
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to generate a new token but fails to authenticate
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:someBadPassword\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"

  Scenario: User attempts to generate a new token without authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "401"

  Scenario: Anonymous attempts to send a null byte within the auth header
    Given the current account is "test1"
    And I send the following raw headers:
      """
      Authorization: Basic dABlAHMAdABAAHQAZQBzAHQALgBjAG8AbQA6AFAAYQBzAHMAdwBvMA=
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "400"

  Scenario: Anonymous attempts to send a badly encoded email address
    Given the current account is "test1"
    And I send the following badly encoded headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The request could not be completed because it contains badly encoded data (check encoding)",
        "code": "ENCODING_INVALID"
      }
      """
