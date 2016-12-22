@api/v1
Feature: Update webhook endpoint

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin updates a webhook endpoint's url
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
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
    Then the response status should be "200"
    And the JSON response should be a "webhookEndpoint" with the url "https://example.com"

  Scenario: User attempts to update a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
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

  Scenario: Anonymous user attempts to update a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
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

  Scenario: Admin attempts to update a webhook endpoint for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
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
