@lib/typed_params
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

  Scenario: User sends a request containing a type mismatch (string => integer)
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
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "type mismatch (received integer expected string)",
        "source": {
          "pointer": "/data/attributes/name"
        }
      }
      """

  Scenario: User sends a request containing a type mismatch (object => string)
    Given I am an admin of account "spacex"
    And the current account is "spacex"
    And I use an authentication token
    When I send a POST request to "/v1/accounts/spacex/licenses" with the following:
      """
      {
        "data": {
          "type": "license",
          "attributes": "{}"
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "type mismatch (received string expected object)",
        "source": {
          "pointer": "/data/attributes"
        }
      }
      """

  Scenario: User sends a request containing a type mismatch (integer => object)
    Given I am an admin of account "spacex"
    And the current account is "spacex"
    And I use an authentication token
    When I send a POST request to "/v1/accounts/spacex/policies" with the following:
      """
      {
        "data": {
          "type": "policy",
          "attributes": {
            "maxMachines": { "foo": "bar" }
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "type mismatch (received object expected integer)",
        "source": {
          "pointer": "/data/attributes/maxMachines"
        }
      }
      """

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
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/unpermittedParam"
        }
      }
      """

  @mp
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
