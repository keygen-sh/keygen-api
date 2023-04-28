@api/v1
@ee
Feature: Show environment
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
    And the current account has 1 "environment"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves an environment for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "200"
    And the response body should be a "environment"

  Scenario: Developer retrieves an environment for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "200"
    And the response body should be a "environment"

  Scenario: Sales retrieves an environment for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "200"
    And the response body should be a "environment"

  Scenario: Support retrieves an environment for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "200"
    And the response body should be a "environment"

  Scenario: Read-only retrieves an environment for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "200"
    And the response body should be a "environment"

  Scenario: Admin retrieves an invalid environment for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested environment 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve an environment for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "environments"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: Environment retrieves an environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/environments/$1"
    Then the response status should be "404"

  Scenario: Environment retrieves itself
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "200"

  Scenario: Product retrieves an environment (no environment)
    Given the current account is "test1"
    And the current account has 1 shared "environments"
    And the current account has 1 shared "product"
    And I am a product of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "404"

  Scenario: Product retrieves an environment (in environment)
    Given the current account is "test1"
    And the current account has 3 "environments"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "404"

  Scenario: License retrieves an environment (no environment)
    Given the current account is "test1"
    And the current account has 3 "environments"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "404"

  Scenario: License retrieves an environment (in environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "404"

  Scenario: User retrieves an environment (no environment)
    Given the current account is "test1"
    And the current account has 3 "environments"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "404"

  Scenario: User retrieves an environment (in environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "404"

  Scenario: Anonymous retrieves an environment
    Given the current account is "test1"
    And the current account has 1 "environment"
    When I send a GET request to "/accounts/test1/environments/$0"
    Then the response status should be "401"
