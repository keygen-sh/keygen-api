@api/v1
Feature: Generate authentication token

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin generates a new token via basic authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with a nil expiry

  Scenario: User generates a new token via basic authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with a expiry

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
