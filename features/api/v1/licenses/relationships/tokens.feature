@api/v1
Feature: Generate authentication token for license

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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin generates a license token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": null,
        "maxActivations": null,
        "maxDeactivations": null,
        "activations": 0,
        "deactivations": 0
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a license token with a max activation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxActivations": 1
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": null,
        "maxActivations": 1,
        "maxDeactivations": null,
        "activations": 0,
        "deactivations": 0
      }
      """

  Scenario: Admin generates a license token with a negative max activation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxActivations": -1
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be greater than or equal to 0",
        "source": {
          "pointer": "/data/attributes/maxActivations"
        },
        "code": "MAX_ACTIVATIONS_INVALID"
      }
      """

  Scenario: Admin generates a license token with a negative max deactivation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxDeactivations": -1
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be greater than or equal to 0",
        "source": {
          "pointer": "/data/attributes/maxDeactivations"
        },
        "code": "MAX_DEACTIVATIONS_INVALID"
      }
      """

  Scenario: Admin generates a license token with a set expiry
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": "2016-10-05T22:53:37.000Z",
        "maxActivations": null,
        "maxDeactivations": null,
        "activations": 0,
        "deactivations": 0
      }
      """

  Scenario: Admin generates a license token with a max deactivation count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "maxDeactivations": 1
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "activation-token",
        "expiry": null,
        "maxActivations": null,
        "maxDeactivations": 1,
        "activations": 0,
        "deactivations": 0
      }
      """

  Scenario: Admin generates a license token but sends invalid attributes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens" with the following:
      """
      {
        "data": {
          "type": "tokens",
          "attributes": {
            "bearerId": "$users[0]",
            "bearerType": "users"
          }
        }
      }
      """
    Then the response status should be "400"

  Scenario: Product generates a license token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "licenses"
    And I am a product of account "test1"
    And the current product has 3 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a nil expiry

  Scenario: Product attempts to generate a token for a license it doesn't own
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/tokens"
    Then the response status should be "403"

  Scenario: User attempts to generate a license token
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: Admin attempts to generate a license token for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test2/licenses/$0/tokens"
    Then the response status should be "401"

  Scenario: Admin requests tokens for one of their licenses
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 5 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests a license's tokens
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "licenses"
    And I am a product of account "test1"
    And the current product has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests a license's token
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "licenses"
    And I am a product of account "test1"
    And the current product has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens/$3"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: Product attempts to request tokens for a license it doesn't own
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1/tokens"
    Then the response status should be "403"

  Scenario: License requests their tokens
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: License requests another license's tokens
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1/tokens"
    Then the response status should be "403"

  Scenario: User requests all tokens for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "licenses"
    And the current user has 3 "licenses"
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"

  Scenario: User requests all tokens for another user's license
    Given the current account is "test1"
    And the current account has 2 "users"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[2]"
      }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/tokens"
    Then the response status should be "403"