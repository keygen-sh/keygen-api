@api/v1
Feature: List entitlements

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
    And the current account has 2 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "403"

  Scenario: Admin retrieves all entitlements for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  Scenario: Developer retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 2 "entitlements"

  Scenario: Sales retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 2 "entitlements"

  Scenario: Support retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 5 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 5 "entitlements"

  Scenario: Read-only retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 5 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 5 "entitlements"

  Scenario: Admin retrieves a paginated list of entitlements
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "entitlements"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/entitlements?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/entitlements?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/entitlements?page[number]=2&page[size]=5",
        "meta": {
          "pages": 2,
          "count": 10
        }
      }
      """

  Scenario: Admin retrieves a paginated list of entitlements with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of entitlements with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of entitlements with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all entitlements without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 10 "entitlements"

  Scenario: Admin retrieves all entitlements with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "entitlements"

  Scenario: Admin retrieves all entitlements with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=10"
    Then the response status should be "200"
    And the response body should be an array with 10 "entitlements"

  Scenario: Admin retrieves all entitlements with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all entitlements with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all entitlements for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: License retrieves all their entitlements (has no entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 0 "entitlements"

  Scenario: License retrieves all their entitlements (has entitlements)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "license-entitlements" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 4 "entitlements"

  Scenario: User retrieves all their entitlements (has no entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 0 "entitlements"

  Scenario: User retrieves all their entitlements (has entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And the current account has 3 "policy-entitlement" for the last "policy"
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 1 "license-entitlement" for each "license"
    And all "licenses" belong to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 5 "entitlements"

  Scenario: Product attempts to retrieve all entitlements for their account
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  @ee
  Scenario: Environment retrieves all isolated entitlements (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "entitlements"
    And the current account has 3 shared "entitlements"
    And the current account has 3 global "entitlements"
    And I am the first environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"
    And the response body should be an array of 3 "entitlements" with the following relationships:
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

  @ee
  Scenario: Environment retrieves all shared entitlements (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "entitlements"
    And the current account has 3 shared "entitlements"
    And the current account has 3 global "entitlements"
    And I am the first environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 6 "entitlements"
    And the response body should be an array of 3 "entitlements" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be an array of 3 "entitlements" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
