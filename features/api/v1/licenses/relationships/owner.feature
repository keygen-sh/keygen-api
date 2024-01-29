@api/v1
Feature: License owner relationship
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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "403"

  # Retrieval
  Scenario: Admin retrieves the owner for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses" for the last "user" as "owner"
    And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/test-key/owner"
    Then the response status should be "200"
    And the response body should be a "user"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves the owner for a license (no owner)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "200"
    And the response body should be the following:
      """
      { "data": null }
      """
    And the response should contain a valid signature header for "test1"

  @ee
  Scenario: Environment retrieves the owner of a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared+owned "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: Product retrieves the owner for a license
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: Product retrieves the owner for a license of another product
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[2]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "404"

  Scenario: Owner attempts to retrieve the owner for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: User attempts to retrieve the owner for their license
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the first "user" as "owner"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: User attempts to retrieve the owner for a license
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/0/owner"
    Then the response status should be "404"

  Scenario: License attempts to retrieve their owner (without permission)
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the first "user" as "owner"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "403"

  Scenario: License attempts to retrieve their owner (with permission)
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license" for the first "user" as "owner"
    And the last "license" has the following permissions:
      """
      ["user.read"]
      """
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "200"
    And the response body should be a "user"

  Scenario: Admin attempts to retrieve the owner for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/owner"
    Then the response status should be "401"

  # Updating
  Scenario: Admin changes a license's owner relationship to another user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "userId": "$users[1]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[2]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": { "type": "users", "id": "$users[2]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a license's owner relationship
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      { "data": null }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's owner relationship to a non-existent user (default)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's owner relationship to a non-existent user (v1.5)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I use an authentication token
    And I use API version "1.5"
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's owner relationship to a user for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 2 "users"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "userId": "$users[0]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test2/licenses/$0/owner" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's owner relationship to another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 4 "users"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[0]"
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's owner relationship to a new user they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "users"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's owner relationship to a new user for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 3 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[0]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's owner relationship that would exceed group limits
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the last "group" has the following attributes:
      """
      { "maxLicenses": 1 }
      """
    And the current account has 3 "users"
    And all "users" have the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
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
        "detail": "license count has exceeded maximum allowed by current group (1)",
        "code": "GROUP_LICENSE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Owner attempts to change their license's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[0]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to change their license's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to change a license's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      { "protected": false }
      """
    And the current account has 2 "users"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the first user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[2]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to change their owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to change a license's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      { "protected": false }
      """
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 1 "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$1/owner" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to change a license's owner relationship
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": null
      }
      """
    When I send a PUT request to "/accounts/test1/licenses/$0/owner" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[0]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
