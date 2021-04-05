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
    And the JSON response should be an array with 3 "entitlements"

  Scenario: Developer retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "entitlements"

  Scenario: Sales retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "entitlements"

  Scenario: Support retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 5 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "entitlements"

  Scenario: Admin retrieves a paginated list of entitlements
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "entitlements"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/entitlements?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/entitlements?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/entitlements?page[number]=4&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """

  Scenario: Admin retrieves a paginated list of entitlements with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "entitlements"
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
    And the current account has 20 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all entitlements without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "entitlements"

  Scenario: Admin retrieves all entitlements with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "entitlements"

  Scenario: Admin retrieves all entitlements with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "entitlements"

  Scenario: Admin retrieves all entitlements with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all entitlements with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "entitlements"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all entitlements for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all entitlements for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "entitlements"
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error

  Scenario: Product attempts to retrieves all entitlements for their account
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/entitlements"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
