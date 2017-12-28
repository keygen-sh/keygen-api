@lib/typed_parameters
Feature: Typed parameters

  Background:
    Given I send and accept JSON
    And the following "accounts" exist:
      | Name   | Slug   |
      | Tesla  | tesla  |
      | SpaceX | spacex |
    And there exists 1 "plan"

  Scenario: User sends a valid request
    Given I am an admin of account "tesla"
    And the current account is "tesla"
    And I use an authentication token
    When I send a POST request to "/v1/accounts/tesla/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Self-driving Car"
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: User sends a request containing a type mismatch
    Given I am an admin of account "spacex"
    And the current account is "spacex"
    And I use an authentication token
    When I send a POST request to "/v1/accounts/spacex/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": 1
          }
        }
      }
      """
    Then the response status should be "400"

  Scenario: User sends a request containing an unpermitted parameter
    Given I am an admin of account "tesla"
    And the current account is "tesla"
    And I use an authentication token
    When I send a POST request to "/v1/accounts/tesla/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Self-driving Car",
            "unpermitted_param": "parameter"
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: unpermittedParam"
      }
      """

  Scenario: User sends a request with unpermitted parameters that match other permitted keys
    When I send a POST request to "/v1/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "password": "goog",
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "email": "bad@actor.io",
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "name": "Larry Page",
                    "email": "lpage@keygen.sh",
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "400"
