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

  # Retrieval
  Scenario: Admin retrieves the entitlements for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

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
    And the response body should be an array with 7 "entitlements"

  Scenario: Admin attempts to retrieve the entitlements for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "401"

  @ee
  Scenario: Environment retrieves the entitlements for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And the current account has 3 isolated "license-entitlements" for each "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

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
    And the response body should be an array with 3 "entitlements"

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
    Then the response status should be "404"

  Scenario: License retrieves their entitlements
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for the last "product"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "license-entitlements" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 4 "entitlements"

  Scenario: User attempts to retrieve the entitlements for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses" for the last "user" as "owner"
    And the current account has 2 "license-entitlements" for the first "license"
    And the current account has 4 "license-entitlements" for the second "license"
    And the current account has 6 "license-entitlements" for the third "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 2 "entitlements"

  Scenario: User attempts to retrieve the entitlements for a license they don't own
    Given the current account is "test1"
    And the current account has 1 userless "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements"
    Then the response status should be "404"

  Scenario: Admin retrieves an entitlement for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

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
    And the response body should be a "entitlement"

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
    And the response body should be an "entitlement"

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
    Then the response status should be "404"

  # Attachment
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
    And the response body should be an array with 3 "license-entitlements"
    And the current account should have 3 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin attaches shared entitlements to a global license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 shared "entitlements"
    And the current account has 1 global "license"
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
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (a record's environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin attaches shared entitlements to a shared license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 shared "entitlements"
    And the current account has 1 global "entitlements"
    And the current account has 1 shared "license"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
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
    And the response body should be an array with 3 "license-entitlements"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 3 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin attaches mixed entitlements to a shared license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 isolated "entitlement"
    And the current account has 1 shared "entitlement"
    And the current account has 1 global "entitlement"
    And the current account has 1 shared "license"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
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
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (a record's environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attaches empty entitlements to a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      { "data": [] }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "length must be greater than or equal to 1",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
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
        "code": "ENTITLEMENT_CONFLICT",
        "source": {
          "pointer": "/data/relationships/entitlement"
        }
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
        "code": "ENTITLEMENT_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/entitlement"
        }
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

  @ee
  Scenario: Environment attaches isolated entitlements to an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "entitlements"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" }
        ]
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "license-entitlements"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And the current account should have 3 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared entitlements to an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 shared "entitlements"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" }
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared entitlements to a global license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 shared "entitlements"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" }
        ]
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "license-entitlements"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 3 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared entitlements to a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "entitlements"
    And the current account has 1 global "entitlements"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" }
        ]
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "license-entitlements"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 3 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches mixed entitlements to a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "entitlement"
    And the current account has 1 shared "entitlement"
    And the current account has 1 global "entitlement"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" }
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
    And the response body should be an array with 2 "license-entitlements"
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
    Then the response status should be "404"
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
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Detachment
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

  Scenario: Admin detaches empty entitlements from a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 3 "license-entitlements" for existing "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      { "data": [] }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "length must be greater than or equal to 1",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
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

  @ee
  Scenario: Admin detaches shared entitlements from a shared license
    Given the current account is "test1"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "license"
    And the current account has 2 shared "license-entitlements" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" }
        ]
      }
      """
    Then the response status should be "204"
    And the current account should have 0 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 2 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin detaches shared entitlements from a global license
    Given the current account is "test1"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "license"
    And the current account has 2 global "license-entitlements" for the last "license"
    And the current account has 2 shared "license-entitlements" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements" with the following:
      """
      {
        "data": [
          { "type": "entitlements", "id": "$entitlements[2]" },
          { "type": "entitlements", "id": "$entitlements[3]" }
        ]
      }
      """
    Then the response status should be "204"
    And the current account should have 2 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 4 "entitlements"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin detaches global entitlements from a global license
    Given the current account is "test1"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "license"
    And the current account has 2 global "license-entitlements" for the last "license"
    And the current account has 2 shared "license-entitlements" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
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
    And the current account should have 4 "license-entitlements"
    And the current account should have 0 "policy-entitlements"
    And the current account should have 4 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches isolated entitlements from an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And the current account has 4 isolated "license-entitlements" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements?environment=isolated" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[3]" }
        ]
      }
      """
    Then the response status should be "204"

  @ee
  Scenario: Environment detaches shared entitlements from a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And the current account has 2 shared "license-entitlements" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements?environment=shared" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[1]" }
        ]
      }
      """
    Then the response status should be "204"

  @ee
  Scenario: Environment detaches shared entitlements from a global license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And the current account has 2 shared "license-entitlements" for the last "license"
    And the current account has 2 global "license-entitlements" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements?environment=shared" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[0]" },
          { "type": "entitlement", "id": "$entitlements[1]" }
        ]
      }
      """
    Then the response status should be "204"

  @ee
  Scenario: Environment detaches global entitlements from a global license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And the current account has 2 shared "license-entitlements" for the last "license"
    And the current account has 2 global "license-entitlements" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/entitlements?environment=shared" with the following:
      """
      {
        "data": [
          { "type": "entitlement", "id": "$entitlements[2]" },
          { "type": "entitlement", "id": "$entitlements[3]" }
        ]
      }
      """
    Then the response status should be "403"

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
    Then the response status should be "404"

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
    Then the response status should be "404"

  Scenario: User attempts to detach entitlements from their license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 2 "license-entitlements" for existing "licenses"
    And the current account has 1 "user"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
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
