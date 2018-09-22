@api/v1
Feature: Create webhook endpoint

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
    When I send a POST request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "403"

  Scenario: Admin creates a webhook endpoint for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "webhook-endpoint" with the url "https://example.com"
    And the JSON response should be a "webhook-endpoint" with the following "subscriptions":
      """
      ["*"]
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin creates a webhook endpoint for their account that subscribes to certain events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com",
            "subscriptions": [
              "license.created",
              "license.created",
              "license.updated",
              "license.deleted"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "webhook-endpoint" with the url "https://example.com"
    And the JSON response should be a "webhook-endpoint" with the following "subscriptions":
      """
      [
        "license.created",
        "license.updated",
        "license.deleted"
      ]
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin creates a webhook endpoint for their account that subscribes to no events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com",
            "subscriptions": []
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must have at least 1 webhook event subscription",
        "source": {
          "pointer": "/data/attributes/subscriptions"
        },
        "code": "SUBSCRIPTIONS_TOO_SHORT"
      }
      """

  Scenario: Admin creates a webhook endpoint for their account that subscribes to all events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com",
            "subscriptions": ["*"]
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "webhook-endpoint" with the url "https://example.com"
    And the JSON response should be a "webhook-endpoint" with the following "subscriptions":
      """
      ["*"]
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin creates a webhook endpoint for their account that subscribes to non-existent events
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com",
            "subscriptions": [
              "license.created",
              "foo.bar",
              "baz.qux"
            ]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "unsupported webhook event type for subscription",
        "source": {
          "pointer": "/data/attributes/subscriptions"
        },
        "code": "SUBSCRIPTIONS_NOT_ALLOWED"
      }
      """

  Scenario: Admin creates a webhook endpoint with missing url
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {}
        }
      }
      """
    Then the response status should be "400"

  Scenario: Admin creates a webhook endpoint with a non-https url
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "http://example.com"
          }
        }
      }
      """
    Then the response status should be "422"

  Scenario: Admin creates a webhook endpoint with an invalid url protocol
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
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
          "type": "webhook-endpoint",
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
          "type": "webhook-endpoint",
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
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com"
          }
        }
      }
      """
    Then the response status should be "401"
