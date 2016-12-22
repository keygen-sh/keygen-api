@api/v1
Feature: Create webhook endpoint

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin creates a webhook endpoint for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhookEndpoint",
          "attributes": {
            "url": "https://example.com"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "webhookEndpoint" with the url "https://example.com"

  Scenario: Admin creates a webhook endpoint with missing url
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhookEndpoint",
          "attributes": {}
        }
      }
      """
    Then the response status should be "400"

  Scenario: Admin creates a webhook endpoint with an invalid url protocol
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhookEndpoint",
          "attributes": {
            "url": "ssh://example.com"
          }
        }
      }
      """
    Then the response status should be "422"

  Scenario: User attempts to create a webhook endpoint
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhookEndpoint",
          "attributes": {
            "url": "https://example.com"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Unauthenticated user attempts to create a webhook endpoint
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhookEndpoint",
          "attributes": {
            "url": "https://example.com"
          }
        }
      }
      """
    Then the response status should be "401"

  Scenario: Admin of another account attempts to create a webhook endpoint
    Given I am an admin of account "test2"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhookEndpoint",
          "attributes": {
            "url": "https://example.com"
          }
        }
      }
      """
    Then the response status should be "401"
