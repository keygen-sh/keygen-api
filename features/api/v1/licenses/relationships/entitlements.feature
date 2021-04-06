@api/v1
Feature: License entitlements relationship

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
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "403"

  Scenario: Admin retrieves the entitlements for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "entitlements"

  Scenario: Admin retrieves the entitlements for a license key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 2 "policy-entitlements" for existing "policies"
    And the current account has 1 "license" for existing "policies"
    And the first "license" has the following attributes:
      """
      { "key": "example-license-key" }
      """
    And the current account has 5 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/example-license-key/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 7 "entitlements"

  Scenario: Admin attempts to retrieve the entitlements for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "401"

  Scenario: Product retrieves the entitlements for a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "entitlements"

  Scenario: Product retrieves the entitlements for a license of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the entitlements for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 5 "license-entitlements" for existing "licenses"
    And the current account has 1 "user"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "entitlements"

  Scenario: User attempts to retrieve the entitlements for a license they don't own
    Given the current account is "test1"
    And the current account has 1 userless "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "403"

  Scenario: Admin retrieves an entitlement for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: Product retrieves an entitlement for a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: User attempts to retrieve an entitlements for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 5 "license-entitlements" for existing "licenses"
    And the current account has 1 "user"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be an "entitlement"

  Scenario: User attempts to retrieve an entitlements for a license they don't own
    Given the current account is "test1"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements/$0"
    Then the response status should be "403"

  Scenario: Admin attaches entitlements to a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[1]" },
          { "type": "entitlement", "id": "$entitlements[2]" }
        ]
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 3 "license-entitlements"
    And the current account should have 3 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attaches an entitlement to a license that already exists as a policy entitlement
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" for existing "policies"
    And the current account has 1 "policy-entitlement" for existing "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "already exists (entitlement is attached through policy)",
        "source": {
          "pointer": "/data/relationships/entitlement"
        },
        "code": "ENTITLEMENT_CONFLICT"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to attach an entitlement to a license that already exists as a license entitlement
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "license-entitlement" for existing "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "already exists",
        "source": {
          "pointer": "/data/relationships/entitlement"
        },
        "code": "ENTITLEMENT_TAKEN"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to attach entitlements to a license with an invalid entitlement ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "d22692b1-0b4b-4cb7-9e3e-449e0fdf9cd8" },
          { "type": "entitlement", "id": "$entitlements[2]" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "source": {
          "pointer": "/data/relationships/entitlement"
        },
        "code": "ENTITLEMENT_BLANK"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to attach an entitlement to a license for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "entitlement"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attaches entitlements to a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 4 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[3]" }
        ]
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 2 "license-entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to attach entitlements to a license it doesn't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "entitlements"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to attach entitlements to themselves
    Given the current account is "test1"
    And the current account has 2 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to attach entitlements to a license
    Given the current account is "test1"
    And the current account has 2 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin detaches entitlements from a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[1]" },
          { "type": "entitlement", "id": "$entitlements[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And the current account should have 0 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 3 "entitlements"
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to detach entitlements from a license with an invalid entitlement ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "d22692b1-0b4b-4cb7-9e3e-449e0fdf9cd8" },
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "entitlement 'd22692b1-0b4b-4cb7-9e3e-449e0fdf9cd8' relationship not found",
        "source": {
          "pointer": "/data/0"
        }
      }
      """
    And the current account should have 3 "license-entitlement"
    And the current account should have 0 "policy-entitlement"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to detach entitlements from a license that is inherited from the policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "license" for existing "policies"
    And the current account has 1 "license-entitlement" for existing "licenses"
    And the current account has 1 "policy-entitlement" for existing "policies"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[1]" }
        ]
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "cannot detach entitlement '$entitlements[1]' (entitlement is attached through policy)",
        "source": {
          "pointer": "/data/1"
        }
      }
      """

  Scenario: Admin attempts to detach an entitlement from a license for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "license-entitlement" for existing "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "401"

  Scenario: Product detaches entitlements from a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 4 "license-entitlements" for existing "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[3]" }
        ]
      }
      """
    Then the response status should be "204"

  Scenario: Product attempts to detach entitlements from a license it doesn't own
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 2 "license-entitlements" for existing "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" }
        ]
      }
      """
    Then the response status should be "403"

  Scenario: License attempts to detach entitlements to themselves
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 2 "license-entitlements" for existing "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "403"

  Scenario: License attempts to detach entitlements from another license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 2 "licenses" for existing "policies"
    And the current account has 1 "license-entitlement" for existing "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "403"

  Scenario: User attempts to detach entitlements from a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 2 "license-entitlements" for existing "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" }
        ]
      }
      """
    Then the response status should be "403"