@api/v1
Feature: Display who the current API token bearer is

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should not be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"

  Scenario: Admin requests their profile
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"
    And the response body should be a "user"
    And the response body should contain an included "token" with the following relationships:
      """
      {
        "bearer": {
          "links": { "related": "/v1/accounts/$accounts[0]/users/$users[0]" },
          "data": { "type": "users", "id": "$users[0]" }
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment requests their profile
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/me?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "environment"

  Scenario: Product requests their profile
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: User requests their profile
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: License requests their profile (token)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "authenticationStrategy": "TOKEN" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: License requests their profile (key)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: License requests their profile (invalid key)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I authenticate with an invalid key
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "LICENSE_INVALID"
      }
      """

  Scenario: Anonymous requests their profile
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
