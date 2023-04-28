@api/v1
Feature: Group users relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves all users for a group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Admin retrieves all users for a group that doesn't exist
    Given the current account is "test1"
    And the current account has 2 "groups"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/770e6d1e-e102-4492-bafa-0dd3c886fe93/users"
    Then the response status should be "404"

  @ee
  Scenario: Environment retrieves all users for a group
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "groups"
    And the current account has 5 isolated "users" for the first "group"
    And the current account has 2 isolated "users" for the second "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "200"
    And the response body should be an array with 5 "users"

  Scenario: Product retrieves all users for a group (not associated)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "product"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "200"
    And the response body should be an array with 0 "users"

  Scenario: Product retrieves all users for a group (associated)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "product"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "policy" for an existing "product"
    And the current account has 3 "licenses" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "200"
    And the response body should be an array with 2 "users"

  Scenario: User retrieves all users for their group (is owner)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "users"
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the fifth "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "200"
    And the response body should be an array with 2 "users"

  Scenario: User retrieves all users for a group (is not member)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "users"
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$1/users"
    Then the response status should be "404"

  Scenario: User retrieves all users for their group (is member)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "users"
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$1/users"
    Then the response status should be "403"

  Scenario: License retrieves all users for a group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "404"

  Scenario: License retrieves all users for their group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the current account has 1 "license" in the first "group"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "403"

  Scenario: Anonymous retrieves all users for a group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    When I send a GET request to "/accounts/test1/groups/$0/users"
    Then the response status should be "401"
