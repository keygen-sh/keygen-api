@api/v1
Feature: Show machine process

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
    And the current account has 1 "process"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a process for their account (alive)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "process"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "interval": 600,
        "status": "ALIVE"
      }
      """
    And time is unfrozen

  Scenario: Admin retrieves a process for their account (dead)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "process"
    And the first "process" has the following attributes:
      """
      { "lastHeartbeatAt": "2022-04-14T14:52:48.000Z" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-04-14T14:52:48.000Z",
        "nextHeartbeat": "2022-04-14T15:02:48.000Z",
        "status": "DEAD"
      }
      """
    And time is unfrozen

  Scenario: Developer retrieves a process for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "processes"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"

  Scenario: Sales retrieves a process for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "processes"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"

  Scenario: Support retrieves a process for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "processes"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"

  Scenario: Read-only retrieves a process for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "processes"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves an invalid process for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested machine process 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  @ee
  Scenario: Environment retrieves an isolated process
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "process"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "process"

  @ee
  Scenario: Environment retrieves a shared process
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "process"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "process"

  @ee
  Scenario: Environment retrieves a global process
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "process"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "process"

  Scenario: Product retrieves a process for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  Scenario: Product attempts to retrieve a process for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "process"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "404"

  Scenario: User retrieves a process for their license (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  Scenario: User retrieves a process for their license (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  Scenario: User retrieves a process for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "processes"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "404"

  Scenario: License retrieves a process for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  Scenario: License retrieves a process for another license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "process"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a process for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "processes"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error
