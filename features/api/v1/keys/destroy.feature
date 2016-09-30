@api/v1
Feature: Delete key

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin deletes one of their keys
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "keys"
    And I use my auth token
    When I send a DELETE request to "/keys/$2"
    Then the response status should be "204"
    And the current account should have 2 "keys"

  Scenario: User attempts to delete a key for their account
    Given I am on the subdomain "test1"
    And the current account has 3 "keys"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my auth token
    When I send a DELETE request to "/keys/$1"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "keys"

  Scenario: Anonymous user attempts to delete a key for their account
    Given I am on the subdomain "test1"
    And the current account has 3 "keys"
    When I send a DELETE request to "/keys/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "keys"

  Scenario: Admin attempts to delete a key for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the current account has 3 "keys"
    And I use my auth token
    When I send a DELETE request to "/keys/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "keys"
