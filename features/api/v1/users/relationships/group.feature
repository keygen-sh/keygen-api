@api/v1
Feature: User group relationship

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
    And the current account has 1 "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "403"

  Scenario: Admin retrieves the group for a user (by ID)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "200"
    And the response body should be a "group"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves the group for a user (by email)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      {
        "email": "test@keygen.example",
        "groupId": "$groups[0]"
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/test@keygen.example/group"
    Then the response status should be "200"
    And the response body should be a "group"
    And the response should contain a valid signature header for "test1"

  @ee
  Scenario: Environment retrieves the group for a shared user
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "group"
    And the current account has 1 shared "user" for the last "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Product retrieves the group for a user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Product retrieves the group for a user of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "group"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "200"

  Scenario: User attempts to retrieve the group for their profile
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: User attempts to retrieve the group of another user
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And all "users" have the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$2/group"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the group for their user (not in group)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the group for their user (in group)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the group for a user of another account
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/group"
    Then the response status should be "401"

  Scenario: Admin changes a user's group relationship to another group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[2]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]/group" },
          "data": { "type": "groups", "id": "$groups[2]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a user's group relationship
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      { "data": null }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]/group" },
          "data": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a user's policy relationship to a non-existent group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "group"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "ef842664-16c5-4c22-b415-fa9f538e9035"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "GROUP_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a user's group relationship to a group for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 2 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      {
        "groupId": "$groups[0]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test2/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[1]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a user's group relationship to another group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 2 "groups"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]/group" },
          "data": { "type": "groups", "id": "$groups[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a user's group relationship to a new group for a user they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 2 "groups"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]/group" },
          "data": { "type": "groups", "id": "$groups[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to change their group relationship
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes another user's group relationship to a different group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 2 "users"
    And all "users" have the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$2/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[1]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License changes a user's group relationship to another group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous changes a user's group relationship to a different group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": null }
      """
    When I send a PUT request to "/accounts/test1/users/$1/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
