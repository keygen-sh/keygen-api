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
    # And the first error should have the following properties:
    #   """
    #   {
    #     "title": "Bad request",
    #     "detail": "invalid character encoding"
    #   }
    #   """
