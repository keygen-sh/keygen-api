@api/v1
Feature: Update webhook endpoint

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
    And the current account has 3 "webhook-endpoints"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$2"
    Then the response status should be "403"

  Scenario: Admin updates a webhook endpoint's url
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "id": "$webhook-endpoints[0].id",
          "attributes": {
            "url": "https://example.com"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "webhook-endpoint" with the url "https://example.com"

  Scenario: User attempts to update a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
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

  Scenario: Anonymous user attempts to update a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
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

  Scenario: Admin attempts to update a webhook endpoint for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
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
