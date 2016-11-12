@api/v1
Feature: List webhook endpoints

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves all webhook endpoints for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "webhookEndpoints"

  Scenario: Admin retrieves a paginated list of webhook endpoints
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "webhookEndpoints"

  Scenario: Admin retrieves a paginated list of webhook endpoints with a page size that is too high
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook endpoints with a page size that is too low
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of webhook endpoints with an invalid page number
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook endpoints without a limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "webhookEndpoints"

  Scenario: Admin retrieves all webhook endpoints with a low limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 10 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "webhookEndpoints"

  Scenario: Admin retrieves all webhook endpoints with a high limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "webhookEndpoints"

  Scenario: Admin retrieves all webhook endpoints with a limit that is too high
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all webhook endpoints with a limit that is too low
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "webhookEndpoints"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all webhook endpoints for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use an authentication token
    When I send a GET request to "/webhook-endpoints"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all webhook endpoints for their account
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "webhookEndpoints"
    When I send a GET request to "/webhook-endpoints"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
