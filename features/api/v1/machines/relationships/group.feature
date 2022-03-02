@api/v1
Feature: Machine group relationship

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
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "403"

  Scenario: Admin retrieves the group for a machine (by ID)
    Given the current account is "test1"
    And the current account has 1 "machine"
    And the current account has 1 "group"
    And the last "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "200"
    And the JSON response should be a "group"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves the group for a machine (by fingerprint)
    Given the current account is "test1"
    And the current account has 1 "machine"
    And the current account has 1 "group"
    And the last "machine" has the following attributes:
      """
      {
        "fingerprint": "7bb42565fb4e555fe3bf902dd3f1e5c3",
        "groupId": "$groups[0]"
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/7bb42565fb4e555fe3bf902dd3f1e5c3/group"
    Then the response status should be "200"
    And the JSON response should be a "group"
    And the response should contain a valid signature header for "test1"

  Scenario: Product retrieves the group for a machine
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "200"
    And the JSON response should be a "group"

  Scenario: Product retrieves the group for a machine of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "group"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the group for a machine they own
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 1 "user"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the group for a machine they don't own
    Given the current account is "test1"
    And the current account has 1 "group"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 2 "users"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the group for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 1 "group"
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the group for a machine of another account
    Given the current account is "test1"
    And the current account has 3 "machines"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/group"
    Then the response status should be "401"

  Scenario: Admin changes a machine's group relationship to another group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[2]"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/group" },
          "data": { "type": "groups", "id": "$groups[2]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a machine's group relationship
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
      """
      { "data": null }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/group" },
          "data": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a machine's policy relationship to a non-existent group
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the current account has 1 "group"
    And the last "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
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
        "code": "GROUP_BLANK",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a machine's group relationship to a group for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 2 "groups"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      {
        "groupId": "$groups[0]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test2/machines/$/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a machine's group relationship to another group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 2 "groups"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
      """
      {
        "data": {
          "type": "groups",
          "id": "$groups[1]"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/group" },
          "data": { "type": "groups", "id": "$groups[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a machine's group relationship to a new group for a machine they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 2 "groups"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to change a machine's group relationship
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 2 "users"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes a machine's group relationship to another group for a machine they don't own
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 2 "groups"
    And the current account has 2 "users"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License changes a machine's group relationship to another group
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the current account has 2 "groups"
    And the last "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous changes a machine's group relationship to a different group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "groupId": null }
      """
    When I send a PUT request to "/accounts/test1/machines/$0/group" with the following:
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
