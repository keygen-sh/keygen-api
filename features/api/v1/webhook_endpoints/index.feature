@api/v1
Feature: List webhook endpoints

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
    And the current account has 3 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "403"

  Scenario: Admin retrieves all webhook endpoints for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "200"
    And the response body should be an array with 3 "webhook-endpoints"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a paginated list of webhook endpoints
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "webhook-endpoints"

  Scenario: Admin retrieves a paginated list of webhook endpoints with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook endpoints with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook endpoints with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook endpoints without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "200"
    And the response body should be an array with 10 "webhook-endpoints"

  Scenario: Admin retrieves all webhook endpoints with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "webhook-endpoints"

  Scenario: Admin retrieves all webhook endpoints with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "webhook-endpoints"

  Scenario: Admin retrieves all webhook endpoints with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook endpoints with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "webhook-endpoints"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all webhook endpoints for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Environment attempts to retrieve all isolated webhook endpoints for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "webhook-endpoints"
    And the current account has 3 shared "webhook-endpoints"
    And the current account has 3 global "webhook-endpoints"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "webhook-endpoints"

  @ee
  Scenario: Environment attempts to retrieve all shared webhook endpoints for their account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "webhook-endpoints"
    And the current account has 3 shared "webhook-endpoints"
    And the current account has 3 global "webhook-endpoints"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "webhook-endpoints"

  Scenario: Product attempts to retrieve all webhook endpoints for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "200"
    And the response body should be an array with 0 "webhook-endpoints"

  Scenario: License attempts to retrieve all webhook endpoints for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 3 "webhook-endpoints"
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all webhook endpoints for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "webhook-endpoints"
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: Anonymous attempts to retrieve all webhook endpoints for an account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    When I send a GET request to "/accounts/test1/webhook-endpoints"
    Then the response status should be "401"
    And the response body should be an array of 1 error
