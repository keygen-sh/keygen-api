@api/v1
Feature: Show group

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
    And the current account has 1 "group"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a group for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Developer retrieves a group for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Sales retrieves a group for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Support retrieves a group for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Read-only retrieves a group for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Admin retrieves an invalid group for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested group 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve a group for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "groups"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ce
  Scenario: Environment retrieves a group (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves a group (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be an "group"

  @ee
  Scenario: Environment retrieves a group (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be an "group"

  Scenario: Product retrieves a group
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: User retrieves a group (not a member)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "403"

  Scenario: User retrieves a group (a member)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: User retrieves a group (an owner)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "user"
    And the current account has 1 "group-owners"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: License retrieves a group (not a member)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "403"

  Scenario: License retrieves a group (a member)
    Given the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Anonymous retrieves a group
    Given the current account is "test1"
    And the current account has 3 "groups"
    When I send a GET request to "/accounts/test1/groups/$0"
    Then the response status should be "401"
