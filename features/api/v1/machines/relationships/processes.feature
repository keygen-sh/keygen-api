@api/v1
Feature: Machine processes relationship
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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "403"

  # Index
  Scenario: Admin retrieves a paginated list of processes for a machine with no other pages
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machine"
    And the current account has 2 "processes" for the last "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 2 "processes"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/machines/$machines[0]/processes?page[number]=1&page[size]=5",
        "prev": null,
        "next": null,
        "first": "/v1/accounts/test1/machines/$machines[0]/processes?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/machines/$machines[0]/processes?page[number]=1&page[size]=5",
        "meta": {
          "pages": 1,
          "count": 2
        }
      }
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a paginated list of processes for a machine with other pages
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machine"
    And the current account has 20 "processes" for the last "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "processes"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/machines/$machines[0]/processes?page[number]=1&page[size]=5",
        "prev": null,
        "next": "/v1/accounts/test1/machines/$machines[0]/processes?page[number]=2&page[size]=5",
        "first": "/v1/accounts/test1/machines/$machines[0]/processes?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/machines/$machines[0]/processes?page[number]=4&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """

  Scenario: Admin retrieves the processes for a machine by fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "fingerprint": "foo" }
      """
    And the current account has 3 "processes" for the last "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/foo/processes"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  @ee
  Scenario: Isolated environment retrieves the processes for an isolated machine
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "machine"
    And the current account has 3 isolated "processes" for each "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  @ee
  Scenario: Shared environment retrieves the processes for a shared machine
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "machine"
    And the current account has 3 shared "processes" for each "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  @ee
  Scenario: Shared environment retrieves the processes for a global machine
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "machine"
    And the current account has 3 global "processes" for each "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  Scenario: Product retrieves the processes for a machine
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  Scenario: Product retrieves the processes for a different product's machine
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "404"

  Scenario: License retrieves the processes for a machine
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  Scenario: License retrieves the processes for different license's machine
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 3 "processes" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "404"

  Scenario: User retrieves the processes for their machine (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  Scenario: User retrieves the processes for their machine (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "200"
    And the response body should be an array with 3 "processes"

  Scenario: User retrieves the processes for different user's machine
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "machine"
    And the current account has 3 "processes" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "404"

  # Show
  Scenario: Admin retrieves a process for a machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machine"
    And the current account has 3 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  @ee
  Scenario: Isolated environment retrieves the license for an isolated machine
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "machine"
    And the current account has 1 isolated "process" for each "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  @ee
  Scenario: Shared environment retrieves the license for a shared machine
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "machine"
    And the current account has 1 shared "process" for each "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "process"

  @ee
  Scenario: Shared environment retrieves the license for a global machine
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "machine"
    And the current account has 1 global "process" for each "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  Scenario: Product retrieves a process for a machine
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "200"
    And the response body should be a "process"

  Scenario: Product retrieves the processes for a different product's machine
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "404"

  Scenario: User retrieves a machine's process (license owner)
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the second "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "200"

  Scenario: User retrieves a machine's process (license user)
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "200"

  Scenario: User retireves a machine's process for a different user
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the third "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "404"

  Scenario: License retrieves a machine's process
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "processes" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "200"

  Scenario: License retireves a machine's process for a different license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 3 "processes" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$0"
    Then the response status should be "404"

  Scenario: License retrieves a wrongly scoped machine's process
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 1 "machine" for the first "license"
    And the current account has 1 "machine" for the second "license"
    And the current account has 1 "process" for the first "machine"
    And the current account has 1 "process" for the second "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes/$1"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the processes for a machine of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "machine"
    And the current account has 3 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/processes"
    Then the response status should be "401"
