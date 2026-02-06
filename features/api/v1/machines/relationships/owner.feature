@api/v1
Feature: Machine owner relationship
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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "403"

  # Retrieval
  Scenario: Admin retrieves the owner for a machine (license owner exists)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves the owner a machine (no owner)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "200"
    And the response body should be the following:
      """
      { "data": null }
      """

  @ee
  Scenario: Isolated environment retrieves the owner for an isolated machine
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "user"
    And the current account has 1 isolated "license" for the last "user" as "owner"
    And the current account has 1 isolated "machine" for the last "license" and the last "user" as "owner"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  @ee
  Scenario: Shared environment retrieves the owner for a shared machine
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "users"
    And the current account has 1 shared "license" for the last "user" as "owner"
    And the current account has 1 shared "license-user" for the last "license" and the second "user"
    And the current account has 1 shared "machine" for the last "license" and the last "user" as "owner"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner?environment=shared"
    Then the response status should be "200"
    And the response body should be a "user"

  @ee
  Scenario: Shared environment retrieves the owner for a global machine
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And the current account has 1 global+owned "machine" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: Product retrieves the owner for a machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 2 "machines" for the last "license" and the last "user" as "owner"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$1/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: Product retrieves the owner for a machine of another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 2 "machines" for the last "license" and the last "user" as "owner"
    And I am the first product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the owner for a machine they own
    Given the current account is "test1"
    And the current account has 1 owned "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: User attempts to retrieve the owner for a machine they're associated to
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 owned "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: User attempts to retrieve the owner for a machine they're not associated to
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 owned "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "404"

  Scenario: License attempts to retrieve their owner (default permission)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "403"

  Scenario: License attempts to retrieve their owner (has permission)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And the last "license" has the following attributes:
      """
      { "permissions": ["user.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: License attempts to retrieve the owner for another machine
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And I am the first license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the owner for a machine of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 owned "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/owner"
    Then the response status should be "401"

  # Updating
  Scenario: Admin changes a machine's owner relationship to another user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the second "user"
    And the current account has 1 "license-user" for the last "license" and the third "user"
    And the current account has 1 "machine" for the last "license" and the second "user" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[2]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/owner" },
          "data": { "type": "users", "id": "$users[2]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a machine's owner relationship to a user they're not associated to
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the second "user"
    And the current account has 1 "machine" for the last "license" and the second "user" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[2]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid license user",
        "code": "OWNER_INVALID",
        "source": {
          "pointer": "/data/relationships/owner"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a machine's owner relationship
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 owned "machine"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      { "data": null }
      """
    Then the response status should be "200"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/owner" },
          "data": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a machine's owner relationship to a non-existent user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "8784f31d-ab66-4384-9fec-e69f1cdb189b"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "OWNER_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/owner"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a machine's owner relationship to a user for another account
    Given I am an admin of account "test1"
    And the account "test1" has 1 "machine"
    And the account "test2" has 1 "user" with the following:
      """
      { "id": "ba92f1ac-e8f7-4524-88a4-cfc9f2112e55" }
      """
    And the current account is "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "ba92f1ac-e8f7-4524-88a4-cfc9f2112e55"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "OWNER_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/owner"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a machine's owner relationship to another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 2 "users"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[2]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/owner" },
          "data": { "type": "users", "id": "$users[2]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a machine's owner relationship to another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "users"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And I am the first product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a machine's owner relationship that would exceed group limits
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "group" with the following:
      """
      { "maxMachines": 1 }
      """
    And the current account has 3 "users" for the first "group"
    And the current account has 1 "license" for the first "group" and the first "policy"
    And the current account has 1 "machine" for the first "group" and the first "license"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license-user" for the second "license" and the second "user"
    And the current account has 1 "license-user" for the second "license" and the third "user"
    And the current account has 1 "license-user" for the second "license" and the fourth "user"
    And the current account has 1 "machine" for the second "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$1/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[2]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "machine count has exceeded maximum allowed by current group (1)",
        "code": "GROUP_MACHINE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Owner attempts to change their machine's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to change their machine's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to change a license's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "machine" for the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to change their machine's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "machine" for the first "license"
    And the current account has 1 "user"
    And I am the first license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to change a machine's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "user"
    And I am the first license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to change a machine's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the current account has 1 "user"
    When I send a PUT request to "/accounts/test1/machines/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
