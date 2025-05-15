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
    And the response body should be a "webhook-endpoint" with the url "https://example.com"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin updates a webhook endpoint's url to localhosts
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
            "url": "https://localhost/foo-bar-baz"
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

  Scenario: Admin updates a webhook endpoint's product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "webhook-endpoint" for the first "product"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "relationships": {
            "product": {
              "data": { "type": "product", "id": "$products[1]" }
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "webhook-endpoint"
    And the response body should be a "webhook-endpoint" with the following relationships:
      """
      {
        "product": {
          "links": { "related": "/v1/accounts/$account/products/$products[1]" },
          "data": { "type": "products", "id": "$products[1]" }
        }
      }
      """

  Scenario: Admin removes a webhook endpoint's product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "webhook-endpoint" for the last "product"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "relationships": {
            "product": {
              "data": null
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "webhook-endpoint"
    And the response body should be a "webhook-endpoint" with the following relationships:
      """
      {
        "product": {
          "links": { "related": null },
          "data": null
        }
      }
      """

  Scenario: Admin updates a webhook endpoint's API version to v1.0
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "apiVersion": "1.0"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "webhook-endpoint" with the following attributes:
      """
      { "apiVersion": "1.0" }
      """

  Scenario: Admin updates a webhook endpoint's API version to v1.1
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "apiVersion": "1.1"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "webhook-endpoint" with the following attributes:
      """
      { "apiVersion": "1.1" }
      """

  Scenario: Admin updates a webhook endpoint's API version to v1.2
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "apiVersion": "1.2"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "webhook-endpoint" with the following attributes:
      """
      { "apiVersion": "1.2" }
      """

  Scenario: Admin updates a webhook endpoint's API version an an invalid version
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "apiVersion": "0.0"
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is invalid",
        "source": {
          "pointer": "/data/attributes/apiVersion"
        }
      }
      """

  @ee
  Scenario: Environment attempts to update a shared webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 shared "webhook-endpoints"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/webhook-endpoints/$0" with the following:
      """
      {
        "data": {
          "type": "webhook-endpoint",
          "attributes": {
            "url": "https://shared.example"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "webhook-endpoint" with the url "https://shared.example"

  Scenario: Product attempts to update a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
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
    Then the response status should be "404"

  Scenario: License attempts to update a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "license"
    And I am a license of account "test1"
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
    Then the response status should be "404"

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
    Then the response status should be "404"

  Scenario: Anonymous user attempts to update a webhook endpoint for an account
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
