@api/v1
Feature: Show engine
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
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves an engine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  Scenario: Developer retrieves an engine for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  Scenario: Sales retrieves an engine for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  Scenario: Support retrieves an engine for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  Scenario: Read-only retrieves an engine for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  Scenario: Admin retrieves an invalid engine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested release engine 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve an engine for another account
    Given the current account is "test1"
    But I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ce
  Scenario: Environment retrieves an engine (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves an engine (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  @ee
  Scenario: Environment retrieves an engine (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  Scenario: Product retrieves an engine
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"
    And the response body should be an "engine"

  Scenario: License retrieves an engine
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"

  Scenario: User retrieves an engine
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"

  Scenario: Anonymous retrieves an engine
    Given the current account is "test1"
    When I send a GET request to "/accounts/test1/engines/$0"
    Then the response status should be "200"