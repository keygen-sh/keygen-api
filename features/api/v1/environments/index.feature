@api/v1
@ee
Feature: List environments
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
    And the current account has 2 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: Admin retrieves all environments for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "200"
    And the response body should be an array with 3 "environments"

  Scenario: Developer retrieves all environments for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "200"
    And the response body should be an array with 2 "environments"

  Scenario: Sales retrieves all environments for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "200"
    And the response body should be an array with 2 "environments"

  Scenario: Support retrieves all environments for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 5 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "200"
    And the response body should be an array with 5 "environments"

  Scenario: Read-only retrieves all environments for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 5 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "200"
    And the response body should be an array with 5 "environments"

  Scenario: Admin retrieves a paginated list of environments
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "environments"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/environments?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/environments?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/environments?page[number]=2&page[size]=5",
        "meta": {
          "pages": 2,
          "count": 10
        }
      }
      """

  Scenario: Admin retrieves a paginated list of environments with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of environments with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of environments with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all environments without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "200"
    And the response body should be an array with 10 "environments"

  Scenario: Admin retrieves all environments with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "environments"

  Scenario: Admin retrieves all environments with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?limit=10"
    Then the response status should be "200"
    And the response body should be an array with 10 "environments"

  Scenario: Admin retrieves all environments with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all environments with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all environments for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: Environment attempts to retrieve all environments
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: Product attempts to retrieve all environments (no environment)
    Given the current account is "test1"
    And the current account has 3 "environments"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: Product attempts to retrieve all environments (in environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environments"
    And the current account has 1 isolated "product"
    And I am a product of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: License attempts to retrieve all environments (no environment)
    Given the current account is "test1"
    And the current account has 3 "environments"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: License attempts to retrieve all environments (in environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: User attempts to retrieve all environments (no environment)
    Given the current account is "test1"
    And the current account has 3 "environments"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: User attempts to retrieve all environments (in environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "403"

  Scenario: Anonymous attempts to retrieve all environments
    Given the current account is "test1"
    And the current account has 1 "environment"
    When I send a GET request to "/accounts/test1/environments"
    Then the response status should be "401"
