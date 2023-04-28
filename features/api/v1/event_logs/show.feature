@api/v1
@ee
Feature: Show event logs
  Background:
    Given the following "plan" rows exist:
      | id                                   | name       |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Standard 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1      |
    Given the following "account" rows exist:
      | name     | slug     | plan_id                              |
      | Standard | standard | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Ent      | ent      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is not on Ent tier
    Given the account "standard" is canceled
    Given I am an admin of account "standard"
    And the current account is "standard"
    And the current account has 2 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/standard/event-logs/$0"
    Then the response status should be "403"

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "ent" is canceled
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 1 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a log for their account
    Given I am an admin of account "ent"
    And the current account is "ent"
    And the current account has 3 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "200"
    And the response body should be a "event-log"

  Scenario: Admin retrieves an invalid log for their account
    Given I am an admin of account "ent"
    And the current account is "ent"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested event log 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve a log for another account
    Given I am an admin of account "standard"
    But the current account is "ent"
    And the account "ent" has 3 "event-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: Product attempts to retrieve a log for their account
    Given the current account is "ent"
    And the current account has 1 "product"
    And I am a product of account "ent"
    And I use an authentication token
    And the current account has 3 "event-logs"
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "404"
    And the response body should be an array of 1 error

  Scenario: Environment attempts to retrieve a log for an isolated environment (in isolated environment)
    Given the current account is "ent"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "200"
    And the response body should be a "event-log"

  Scenario: Environment attempts to retrieve a log for a shared environment (in isolated environment)
    Given the current account is "ent"
    And the current account has 1 isolated "environment"
    And the current account has 3 shared "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "404"

  Scenario: Environment attempts to retrieve a log for a global environment (in isolated environment)
    Given the current account is "ent"
    And the current account has 1 isolated "environment"
    And the current account has 3 global "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "404"

  Scenario: Environment attempts to retrieve a log for an isolated environment (in shared environment)
    Given the current account is "ent"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "404"

  Scenario: Environment attempts to retrieve a log for a shared environment (in shared environment)
    Given the current account is "ent"
    And the current account has 1 shared "environment"
    And the current account has 3 shared "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "200"
    And the response body should be a "event-log"

  Scenario: Environment attempts to retrieve a log for a global environment (in shared environment)
    Given the current account is "ent"
    And the current account has 1 shared "environment"
    And the current account has 3 global "event-logs"
    And I am an environment of account "ent"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "200"
    And the response body should be a "event-log"

  Scenario: License attempts to retrieve a log for their account
    Given the current account is "ent"
    And the current account has 1 "license"
    And I am a license of account "ent"
    And I use an authentication token
    And the current account has 3 "event-logs"
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "404"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve a log for their account
    Given the current account is "ent"
    And the current account has 1 "user"
    And I am a user of account "ent"
    And I use an authentication token
    And the current account has 3 "event-logs"
    When I send a GET request to "/accounts/ent/event-logs/$0"
    Then the response status should be "404"
    And the response body should be an array of 1 error
