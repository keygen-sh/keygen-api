@api/v1
Feature: Show machine

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves a machine for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"

  Scenario: Product retrieves a machine for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    And the current product has 1 "machine"
    When I send a GET request to "/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"

  Scenario: User retrieves a machine for their license
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    And the current user has 1 "machine"
    When I send a GET request to "/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"

  Scenario: Product attempts to retrieve a machine for another product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    When I send a GET request to "/machines/$0"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a machine for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the account "test1" has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/machines/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
