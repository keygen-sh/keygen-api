@api/v1
Feature: Show machine component
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
    And the current account has 1 "component"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a component for their account
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "component" with the following:
      """
      {
        "fingerprint": "8151c161b1f6aa75e66646ba73dbdba0",
        "name": "CPU"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"
    And the response body should be a "component"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "component" with the following attributes:
      """
      {
        "fingerprint": "8151c161b1f6aa75e66646ba73dbdba0",
        "name": "CPU"
      }
      """
    And time is unfrozen

  Scenario: Developer retrieves a component for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"

  Scenario: Sales retrieves a component for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"

  Scenario: Support retrieves a component for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"

  Scenario: Read-only retrieves a component for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves an invalid component for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested machine component 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  @ee
  Scenario: Environment retrieves an isolated component
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "component"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "component"

  @ee
  Scenario: Environment retrieves a shared component
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "component"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "component"

  @ee
  Scenario: Environment retrieves a global component
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "component"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "component"

  Scenario: Product retrieves a component for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"
    And the response body should be a "component"

  Scenario: Product attempts to retrieve a component for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "component"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "404"

  Scenario: User retrieves a component for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "components" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"
    And the response body should be a "component"

  Scenario: User retrieves a component for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "components"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "404"

  Scenario: License retrieves a component for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "components" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "200"
    And the response body should be a "component"

  Scenario: License retrieves a component for another license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "component"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a component for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error
