@api/v1
Feature: Group owners relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "403"

  Scenario: Admin retrieves the owners of a group
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "group-owners"

  Scenario: Product retrieves the owners of a group
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "group-owners"

  Scenario: Admin retrieves an owner of a group
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "200"
    And the JSON response should be a "group-owner"

  Scenario: Product retrieves an owner of a group
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "200"
    And the JSON response should be a "group-owner"

  Scenario: User attempts to retrieve the owners of a group (is owner)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the current account has 3 "group-owners" for the first "group"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the owners of a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the owners of a group (is member)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the owners of a group of another account
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "401"

  Scenario: License attempts to retrieves owners of a group
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "403"

  Scenario: License attempts to retrieves an owner of a group
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "403"

  Scenario: Admin attaches owners to a group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 3 "users"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "user", "id": "$users[1]" },
          { "type": "user", "id": "$users[2]" },
          { "type": "user", "id": "$users[3]" }
        ]
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 3 "group-owners"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attaches owners to a group that already exists
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "already exists",
        "code": "USER_TAKEN",
        "source": {
          "pointer": "/data/relationships/user"
        }
      }
      """

  Scenario: Admin attempts to attach owners to a group with an invalid owner ID
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "d22692b1-0b4b-4cb7-9e3e-449e0fdf9cd8" },
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "USER_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/user"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to attach an owner to a group for another account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attaches owners to a group
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 4 "users"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "$users[3]" }
        ]
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 2 "group-owners"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to attach owners to a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "group-owners", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to attach owners to a group (is member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "group-owners", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to attach owners to a group (is owner)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "group-owners", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to attach owners to a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "group-owners", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to attach owners to a group (is member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "user"
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "group-owners", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin detaches owners from a group
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "users"
    And the current account has 3 "group-owners"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the second "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And the third "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[3]"
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And the current account should have 1 "group-owner"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to detach owners from a group with an invalid owner ID
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 3 "users"
    And the current account has 3 "group-owners"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the second "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "$users[2]" },
          { "type": "users", "id": "818f1f34-676b-4e0b-ba57-a98d02263212" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "owner relationship for user '818f1f34-676b-4e0b-ba57-a98d02263212' not found",
        "source": {
          "pointer": "/data/2"
        }
      }
      """
    And the current account should have 3 "group-owners"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to detach an owner from a group for another account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "group-owner"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product detaches owners from a group
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 2 "group-owners"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the second "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to detach owners from a group
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 2 "group-owners"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the second "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "group-owners", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to detach owners from a group
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 3 "users"
    And the current account has 2 "group-owners"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And the second "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[3]"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "group-owners", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
