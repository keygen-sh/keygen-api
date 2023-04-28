@api/v1
Feature: Delete webhook endpoint

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
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$2"
    Then the response status should be "403"

  Scenario: Admin deletes one of their webhook endpoints
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$2"
    Then the response status should be "204"
    And the current account should have 2 "webhook-endpoints"
    And the response should contain a valid signature header for "test1"

  @ee
  Scenario: Environment attempts to delete an isolated webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "webhook-endpoints"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1?environment=isolated"
    Then the response status should be "204"

  Scenario: Product attempts to delete a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-endpoints"

  Scenario: License attempts to delete a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-endpoints"

  Scenario: User attempts to delete a webhook endpoint for their account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-endpoints"

  Scenario: Anonymous user attempts to delete a webhook endpoint for an account
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-endpoints"

  Scenario: Admin attempts to delete a webhook endpoint for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/webhook-endpoints/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-endpoints"
