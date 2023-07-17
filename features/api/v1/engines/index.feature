@api/v1
Feature: List engines
  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "403"

  Scenario: Admin retrieves all engines for their account
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"
    And the response body should be an array of 1 "engine" with the following attributes:
      """
      { "name": "PyPI", "key": "pypi" }
      """

  Scenario: Developer retrieves all engines for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Sales retrieves all engines for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Support retrieves all engines for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Read-only retrieves all engines for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Admin retrieves a paginated list of engines
    Given the following "engines" exist:
      | name      | key       |
      | RubyGems  | rubygems  |
      | OCI       | oci       |
      | Composer  | composer  |
      | npm       | npm       |
    And the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?page[number]=1&page[size]=3"
    Then the response status should be "200"
    And the response body should be an array with 3 "engines"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/engines?page[number]=1&page[size]=3",
        "next": "/v1/accounts/test1/engines?page[number]=2&page[size]=3",
        "last": "/v1/accounts/test1/engines?page[number]=2&page[size]=3",
        "meta": {
          "pages": 2,
          "count": 5
        }
      }
      """

  Scenario: Admin retrieves a paginated list of engines with a page size that is too high
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of engines with a page size that is too low
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of engines with an invalid page number
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all engines without a limit for their account
    Given the following "engines" exist:
      | name      | key       |
      | Cargo     | cargo     |
      | Composer  | composer  |
      | Conan     | conan     |
      | Conda     | conda     |
      | Electron  | electron  |
      | npm       | npm       |
      | Nuget     | nuget     |
      | OCI       | oci       |
      | RubyGems  | rubygems  |
      | Sparkle   | sparkle   |
      | Squirrel  | squirrel  |
      | Swift     | swift     |
      | Tauri     | tauri     |
    And the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 10 "engines"

  Scenario: Admin retrieves all engines with a low limit for their account
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Admin retrieves all engines with a high limit for their account
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?limit=10"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Admin retrieves all engines with a limit that is too high
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all engines with a limit that is too low
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all engines for another account
    Given the current account is "test1"
    But I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: Product retrieves all engines
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: License retrieves all engines
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: User retrieves all engines
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  @ee
  Scenario: Environment retrieves all engines (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am the first environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  @ee
  Scenario: Environment retrieves all engines (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am the first environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Anonymous retrieves all engines
    Given the current account is "test1"
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"
