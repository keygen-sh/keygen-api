@api/v1
Feature: Group licenses relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves all licenses for a group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: Admin retrieves all licenses for a group that doesn't exist
    Given the current account is "test1"
    And the current account has 2 "groups"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/770e6d1e-e102-4492-bafa-0dd3c886fe93/licenses"
    Then the response status should be "404"

  @ee
  Scenario: Environment retrieves all licenses for a group
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "groups"
    And the current account has 5 isolated "licenses" for the first "group"
    And the current account has 2 isolated "licenses" for the second "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "200"
    And the response body should be an array with 5 "licenses"

  Scenario: Product retrieves all licenses for a group (not associated)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "product"
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "200"
    And the response body should be an array with 0 "licenses"

  Scenario: Product retrieves all licenses for a group (associated)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 7 "licenses" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: User retrieves all licenses for their group (is owner)
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
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: User retrieves all licenses for their group (is member)
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "groupId": "$groups[1]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "403"

  Scenario: User retrieves all licenses for a group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And the current account has 7 "licenses" for the last "user" as "owner"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "404"

  Scenario: License retrieves all licenses for their group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "403"

  Scenario: License retrieves all licenses for a group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$1/licenses"
    Then the response status should be "404"

  Scenario: Anonymous retrieves all licenses for a group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    When I send a GET request to "/accounts/test1/groups/$0/licenses"
    Then the response status should be "401"
