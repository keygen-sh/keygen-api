@api/v1
Feature: List groups

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
    And the current account has 2 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "403"

  Scenario: Admin retrieves all groups for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 3 "groups"

  Scenario: Developer retrieves all groups for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 2 "groups"

  Scenario: Sales retrieves all groups for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 2 "groups"

  Scenario: Support retrieves all groups for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 5 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 5 "groups"

  Scenario: Read-only retrieves all groups for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 5 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 5 "groups"

  Scenario: Admin retrieves a paginated list of groups
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "groups"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/groups?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/groups?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/groups?page[number]=4&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """

  Scenario: Admin retrieves a paginated list of groups with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of groups with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of groups with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all groups without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 10 "groups"

  Scenario: Admin retrieves all groups with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "groups"

  Scenario: Admin retrieves all groups with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "groups"

  Scenario: Admin retrieves all groups with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all groups with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all groups for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Environment attempts to retrieve all isolated groups (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "groups"
    And the current account has 3 shared "groups"
    And the current account has 3 global "groups"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 3 "groups"
    And the response body should be an array of 3 "groups" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Environment attempts to retrieve all shared groups (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "groups"
    And the current account has 3 shared "groups"
    And the current account has 3 global "groups"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 6 "groups"
    And the response body should be an array of 3 "groups" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be an array of 3 "groups" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  Scenario: Product attempts to retrieve all groups for their account
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 3 "groups"

  Scenario: User attempts to retrieve all their groups (group owner and member)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 2 "group-owners"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[1]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 2 "groups"

  Scenario: User attempts to retrieve all their groups (group member)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 1 "group"

  Scenario: User attempts to retrieve all their groups (no groups)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 0 "groups"

  Scenario: License attempts to retrieve all their groups (group member)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 1 "group"

  Scenario: License attempts to retrieve all their groups (no groups)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "200"
    And the response body should be an array with 0 "groups"

  Scenario: Anonymous attempts to retrieve all groups for their account
    Given the current account is "test1"
    And the current account has 3 "groups"
    When I send a GET request to "/accounts/test1/groups"
    Then the response status should be "401"
    And the response body should be an array of 1 error
