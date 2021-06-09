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
    And the JSON response should be a "webhook-endpoint" with the signatureAlgorithm "ed25519"
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

  Scenario: Admin creates a webhook endpoint for their account with an Ed25519 signature algorithm
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com/?token=xxx",
            "signatureAlgorithm": "ed25519"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "webhook-endpoint" with the url "https://example.com/?token=xxx"
    And the JSON response should be a "webhook-endpoint" with the signatureAlgorithm "ed25519"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin creates a webhook endpoint for their account with an RSA-PKCS1-PSS signature algorithm
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
            "signatureAlgorithm": "rsa-pss-sha256"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "webhook-endpoint" with the url "https://example.com"
    And the JSON response should be a "webhook-endpoint" with the signatureAlgorithm "rsa-pss-sha256"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin creates a webhook endpoint for their account with an RSA-PKCS1 signature algorithm
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://example.com/",
            "signatureAlgorithm": "rsa-sha256"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "webhook-endpoint" with the url "https://example.com/"
    And the JSON response should be a "webhook-endpoint" with the signatureAlgorithm "rsa-sha256"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin creates a webhook endpoint for their account with an invalid domain
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://invalid",
            "subscriptions": ["*"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a URL with a valid host",
        "source": {
          "pointer": "/data/attributes/url"
        },
        "code": "URL_HOST_INVALID"
      }
      """

  Scenario: Admin creates a webhook endpoint for their account with a forbidden domain
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://api.keygen.sh/v1/accounts/demo/webhook-events",
            "subscriptions": ["*"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a URL with a valid host",
        "source": {
          "pointer": "/data/attributes/url"
        },
        "code": "URL_HOST_INVALID"
      }
      """

  Scenario: Admin creates a webhook endpoint for their account with an invalid URI
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "1230-12e9 c0ascka-ff.a!",
            "subscriptions": ["*"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid URL",
        "source": {
          "pointer": "/data/attributes/url"
        },
        "code": "URL_INVALID"
      }
      """

  Scenario: Admin creates a localhost webhook endpoint for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-endpoints" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://localhost",
            "subscriptions": ["*"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a URL with a valid host",
        "source": {
          "pointer": "/data/attributes/url"
        },
        "code": "URL_HOST_INVALID"
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
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid URL using one of the following protocols: https",
        "source": {
          "pointer": "/data/attributes/url"
        },
        "code": "URL_PROTOCOL_INVALID"
      }
      """

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
