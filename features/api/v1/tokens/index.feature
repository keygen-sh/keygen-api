@api/v1
Feature: List authentication tokens

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin requests their tokens while authenticated
    Given I am on the subdomain "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of "tokens"

  Scenario: Product requeststheir  tokens while authenticated
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of "tokens"

  Scenario: User requests their tokens while authenticated
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of "tokens"

  Scenario: User requests their tokens without authentication
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a GET request to "/tokens"
    Then the response status should be "401"
