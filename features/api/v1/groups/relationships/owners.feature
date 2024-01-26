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

  # Retrieval
  Scenario: Admin retrieves the owners of a group
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "200"
    And the response body should be an array with 3 "group-owners"

  @ee
  Scenario: Environment retrieves the owners of a group
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "groups"
    And the current account has 2 isolated "group-owners" for the first "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "200"
    And the response body should be an array with 2 "group-owners"

  Scenario: Product retrieves the owners of a group
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "200"
    And the response body should be an array with 3 "group-owners"

  Scenario: Admin retrieves an owner of a group
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "200"
    And the response body should be a "group-owner"

  Scenario: Product retrieves an owner of a group
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "200"
    And the response body should be a "group-owner"

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
    Then the response status should be "200"
    And the response body should be an array with 4 "group-owners"

  Scenario: User attempts to retrieve the owners of a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "404"

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
    Then the response status should be "200"
    And the response body should be an array with 3 "group-owners"

  Scenario: License attempts to retrieve the owners of a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the owners of a group (is member)
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And the current account has 1 "license" with the following:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "200"
    And the response body should be an array with 3 "group-owners"

  Scenario: Admin attempts to retrieve the owners of a group of another account
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners"
    Then the response status should be "401"

  Scenario: License attempts to retrieve an owner of a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "404"

  Scenario: License attempts to retrieve an owner of a group (is member)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 1 "license" with the following:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 3 "group-owners" for the last "group"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "200"
    And the response body should be a "group-owner"

  Scenario: User attempts to retrieve an owner of a group (is owner)
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
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "200"
    And the response body should be a "group-owner"

  Scenario: User attempts to retrieve an owner of a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "group"
    And the current account has 3 "group-owners" for the first "group"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "404"

  Scenario: User attempts to retrieve an owner of a group (is member)
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
    When I send a GET request to "/accounts/test1/groups/$0/owners/$0"
    Then the response status should be "200"
    And the response body should be a "group-owner"

  # Attachment
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
    And the response body should be an array with 3 "group-owners"
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

  @ee
  Scenario: Environment attaches isolated owners to an isolated group
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "group"
    And the current account has 4 isolated "users"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
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
    And the response body should be an array with 2 "group-owners"
    And the response body should be an array of 2 "group-owners" with the following relationships:
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
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared owners to an isolated group
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "group"
    And the current account has 4 shared "users"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "$users[3]" }
        ]
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (a record's environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared owners to a shared group
    Given the current account is "test1"
    And the current account has 2 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "group"
    And the current account has 2 shared "users"
    And the current account has 2 global "users"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
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
    And the response body should be an array with 2 "group-owners"
    And the response body should be an array of 2 "group-owners" with the following relationships:
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
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared owners to a global group
    Given the current account is "test1"
    And the current account has 2 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 global "group"
    And the current account has 2 shared "users"
    And the current account has 2 global "users"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "$users[3]" }
        ]
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (a record's environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
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
    And the response body should be an array with 2 "group-owners"
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
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "404"
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
          { "type": "users", "id": "$users[1]" }
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
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" }
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
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "404"
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
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Detachment
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

  @ee
  Scenario: Environment detaches isolated owners from an isolated group
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "group"
    And the current account has 2 isolated "users"
    And the current account has 2 isolated "group-owners"
    And the first "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[1]" }
      """
    And the second "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[2]" }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners?environment=isolated" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" },
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches shared owners from a shared group
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "group"
    And the current account has 2 shared "users"
    And the current account has 2 shared "group-owners"
    And the first "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[2]" }
      """
    And the second "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[3]" }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners?environment=shared" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" },
          { "type": "users", "id": "$users[3]" }
        ]
      }
      """
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches shared owners from a global group
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 global "group"
    And the current account has 2 shared "users"
    And the current account has 2 shared "group-owners"
    And the first "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[2]" }
      """
    And the second "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[3]" }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners?environment=shared" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" },
          { "type": "users", "id": "$users[3]" }
        ]
      }
      """
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches global owners from a global group
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 global "group"
    And the current account has 2 global "users"
    And the current account has 2 global "group-owners"
    And the first "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[2]" }
      """
    And the second "group-owner" has the following attributes:
      """
      { "groupId": "$groups[0]", "userId": "$users[3]" }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners?environment=shared" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" },
          { "type": "users", "id": "$users[3]" }
        ]
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (a record's environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  Scenario: License attempts to detach owners of a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the current account has 1 "group-owner"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to detach owners of a group (is member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "group-owner"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to detach owners of a group (is owner)
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
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to detach owners of a group (is not member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "users"
    And the current account has 1 "group-owner"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to detach owners of a group (is member)
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "group"
    And the current account has 2 "user"
    And the second "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "group-owner"
    And the first "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/groups/$0/owners" with the following:
      """
      {
        "data": [
          { "type": "users", "id": "$users[2]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
