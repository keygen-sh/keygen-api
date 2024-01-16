@api/v1
Feature: Process machine relationship

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
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "403"

  Scenario: Admin retrieves the machine for a process
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "processes"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "200"
    And the response body should be a "machine"
    And the response should contain a valid signature header for "test1"

  @ee
  Scenario: Isolated environment retrieves the machine for an isolated process
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "process"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "200"
    And the response body should be a "machine"

  @ee
  Scenario: Shared environment retrieves the machine for a shared process
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "process"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine?environment=shared"
    Then the response status should be "200"
    And the response body should be a "machine"

  @ee
  Scenario: Shared environment retrieves the machine for a global process
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "process"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: Product retrieves the machine for a process
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: Product retrieves the machine for a process of different product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "process"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the machine for a process they own
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: User attempts to retrieve the machine for a process they have
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: User attempts to retrieve the machine for a process they don't own
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "processes"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "404"

  Scenario: License attempts to retrieves the machine of a process
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the first "license"
    And the current account has 2 "processes" for the first "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$1/machine"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: License attempts to retrieve the machine for a process they don't own
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 2 "processes"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$1/machine"
    Then the response status should be "404"

  Scenario: Anonymous attempts to retrieve a processes's license
    Given the current account is "test1"
    And the current account has 1 "process"
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "401"

  Scenario: Admin attempts to retrieve the machine for a process of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "processes"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/processes/$0/machine"
    Then the response status should be "401"
