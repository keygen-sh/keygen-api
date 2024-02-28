@api/v1
Feature: List machine components
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
    And the current account has 2 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "403"

  Scenario: Admin retrieves all components for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"
    And the response body should be an array with 3 "components"
    And the response should contain a valid signature header for "test1"

  Scenario: Developer retrieves all components for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"

  Scenario: Sales retrieves all components for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"

  Scenario: Support retrieves all components for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"

  Scenario: Read-only retrieves all components for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"

  Scenario: Admin retrieves a paginated list of components
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "components"

  Scenario: Admin retrieves a paginated list of components scoped to product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy"
    And the current account has 1 "machine" for the first "license"
    And the current account has 1 "machine" for the second "license"
    And the current account has 9 "components" for the first "machine"
    And the current account has 6 "components" for the second "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=1&page[size]=100&product=$products[1]"
    Then the response status should be "200"
    And the response body should be an array with 6 "components"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/components?page[number]=1&page[size]=100&product=$products[1]",
        "prev": null,
        "next": null,
        "first": "/v1/accounts/test1/components?page[number]=1&page[size]=100&product=$products[1]",
        "last": "/v1/accounts/test1/components?page[number]=1&page[size]=100&product=$products[1]",
        "meta": {
          "pages": 1,
          "count": 6
        }
      }
      """

  Scenario: Admin retrieves a paginated list of components scoped to license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy"
    And the current account has 1 "machine" for the first "license"
    And the current account has 1 "machine" for the second "license"
    And the current account has 13 "components" for the first "machine"
    And the current account has 4 "components" for the second "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=1&page[size]=100&license=$licenses[0]"
    Then the response status should be "200"
    And the response body should be an array with 13 "components"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/components?license=$licenses[0]&page[number]=1&page[size]=100",
        "prev": null,
        "next": null,
        "first": "/v1/accounts/test1/components?license=$licenses[0]&page[number]=1&page[size]=100",
        "last": "/v1/accounts/test1/components?license=$licenses[0]&page[number]=1&page[size]=100",
        "meta": {
          "pages": 1,
          "count": 13
        }
      }
      """

  Scenario: Admin retrieves a paginated list of components scoped to machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy"
    And the current account has 1 "machine" for the first "license"
    And the current account has 1 "machine" for the second "license"
    And the current account has 2 "components" for the first "machine"
    And the current account has 14 "components" for the second "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=1&page[size]=10&machine=$machines[1]"
    Then the response status should be "200"
    And the response body should be an array with 10 "components"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/components?machine=$machines[1]&page[number]=1&page[size]=10",
        "prev": null,
        "next": "/v1/accounts/test1/components?machine=$machines[1]&page[number]=2&page[size]=10",
        "first": "/v1/accounts/test1/components?machine=$machines[1]&page[number]=1&page[size]=10",
        "last": "/v1/accounts/test1/components?machine=$machines[1]&page[number]=2&page[size]=10",
        "meta": {
          "pages": 2,
          "count": 14
        }
      }
      """

  Scenario: Admin retrieves a paginated list of components scoped to user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy"
    And the current account has 1 "license" for the second "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine" for the first "license"
    And the current account has 1 "machine" for the second "license"
    And the current account has 1 "machine" for the third "license"
    And the current account has 7 "components" for the first "machine"
    And the current account has 14 "components" for the second "machine"
    And the current account has 4 "components" for the third "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=1&page[size]=10&user=$users[1]"
    Then the response status should be "200"
    And the response body should be an array with 10 "components"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/components?page[number]=1&page[size]=10&user=$users[1]",
        "prev": null,
        "next": "/v1/accounts/test1/components?page[number]=2&page[size]=10&user=$users[1]",
        "first": "/v1/accounts/test1/components?page[number]=1&page[size]=10&user=$users[1]",
        "last": "/v1/accounts/test1/components?page[number]=3&page[size]=10&user=$users[1]",
        "meta": {
          "pages": 3,
          "count": 21
        }
      }
      """

  Scenario: Admin retrieves a paginated list of components with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of components with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=1&page[size]=0"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of components with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of components with an invalid page param
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?page=1&size=100"
    Then the response status should be "400"

  Scenario: Admin retrieves all components without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"
    And the response body should be an array with 10 "components"

  Scenario: Admin retrieves all components with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "components"

  Scenario: Admin retrieves all components with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "components"

  Scenario: Admin retrieves all components with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all components with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "components"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?limit=0"
    Then the response status should be "400"

  @ee
  Scenario: Product retrieves all isolated components
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "components"
    And the current account has 1 shared "components"
    And the current account has 1 global "components"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "components"

  @ee
  Scenario: Product retrieves all shared components
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "components"
    And the current account has 1 shared "components"
    And the current account has 1 global "components"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "components"

  Scenario: Product retrieves all components for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And the current account has 5 "components"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"
    And the response body should be an array with 1 "component"

  Scenario: Admin attempts to retrieve all components for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all components for their group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the current account has 2 "machines" for the first "group"
    And the current account has 2 "machines" for the second "group"
    And the current account has 3 "components" for the first "machine"
    And the current account has 1 "component" for the second "machine"
    And the current account has 7 "components" for the third "machine"
    And the current account has 2 "components" for the fourth "machine"
    And the current account has 5 "components"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"
    And the response body should be an array with 0 "components"

  Scenario: User attempts to retrieve all components for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "components" for the last "machine"
    And the current account has 2 "components"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"
    And the response body should be an array with 3 "components"

  Scenario: License retrieves all components for their license with matches
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 3 "components" for the last "machine"
    And the current account has 2 "components"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"
    And the response body should be an array with 3 "components"

  Scenario: License retrieves all components for their license with no matches
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 5 "components"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/components"
    Then the response status should be "200"
    And the response body should be an array with 0 "components"
