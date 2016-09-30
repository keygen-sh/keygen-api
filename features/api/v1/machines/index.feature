@api/v1
Feature: List machines

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves all machines for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "machines"
    And I use my auth token
    When I send a GET request to "/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "machines"

  Scenario: Product retrieves all machines for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 3 "machines"
    And the current product has 1 "machine"
    When I send a GET request to "/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "machine"

  Scenario: Admin attempts to retrieve all machines for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use my auth token
    When I send a GET request to "/machines"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
