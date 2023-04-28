@api/v1
Feature: License group relationship

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
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "403"

  Scenario: Admin retrieves the group for a license (by ID)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "group"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "200"
    And the response body should be a "group"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves the group for a license (by key)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "group"
    And the last "license" has the following attributes:
      """
      {
        "key": "24b0f13bdde2fa58038ec4a813631708",
        "groupId": "$groups[0]"
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/24b0f13bdde2fa58038ec4a813631708/group"
    Then the response status should be "200"
    And the response body should be a "group"
    And the response should contain a valid signature header for "test1"

  @ee
  Scenario: Environment retrieves the group for a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "group"
    And the current account has 1 shared "license" for the last "group"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Product retrieves the group for a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "group"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: Product retrieves the group for a license of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "group"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the group for a license they own (no group)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the group for a license they own (not in group)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "license" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: User attempts to retrieve the group for a license they own (in group)
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
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: User attempts to retrieve the group for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the group for their license (in group)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "group"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "200"
    And the response body should be a "group"

  Scenario: License attempts to retrieve the group for their license (no group)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the group for a license of another account
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/group"
    Then the response status should be "401"

  Scenario: Admin adds a license to a group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's group relationship to another group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[2]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": { "type": "groups", "id": "$groups[2]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a license's group relationship
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
      """
      { "data": null }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's group relationship to a non-existent group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "group"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's group relationship to a group for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 2 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "groupId": "$groups[0]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test2/licenses/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's group relationship to another group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 4 "groups"
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
        "groupId": "$groups[3]"
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "groupId": "$groups[2]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's group relationship to a new group for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "group"
    And the current account has 3 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[1]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[0]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to change a license's group relationship
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the last "license" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$licenses[0]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes a license's group relationship to another group for a license they don't own
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 2 "users"
    And the current account has 2 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[2]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous changes a license's group relationship to a different group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "groupId": null
      }
      """
    When I send a PUT request to "/accounts/test1/licenses/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
