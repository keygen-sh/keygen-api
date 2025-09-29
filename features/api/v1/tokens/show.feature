@api/v1
Feature: Show authentication token

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should not be "403"

  Scenario: Admin requests a token while authenticated
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the response body should be a "token" without a "token" attribute

  Scenario: Admin retrieves an invalid token while authenticated
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested token 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  @ee
  Scenario: Environment requests a token while authenticated
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "token"

  Scenario: Product requests a token while authenticated
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the response body should be a "token"

  Scenario: Product requests a token for their license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "token" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the response body should be a "token"

  Scenario: Product requests a token for a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 1 "token" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "404"

  Scenario: Product requests a token for an environment
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "environment"
    And the current account has 1 "token" for the last "environment"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "404"

  Scenario: Product requests a token for an admin
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "admin"
    And the current account has 1 "token" for the last "admin"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "404"

  Scenario: Product requests a token for their user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "token" for the last "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the response body should be a "token"

  Scenario: Product requests a token for a user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "token" for the last "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "404"

  Scenario: User requests a token while authenticated
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the response body should be a "token"

  Scenario: Anonymous requests a user's token
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "token" for the last "user"
    And I am a user of account "test1"
    When I send a GET request to "/accounts/test1/tokens/$0"
    Then the response status should be "401"
