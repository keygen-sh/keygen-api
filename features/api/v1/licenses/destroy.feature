@api/v1
Feature: Delete license

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin deletes one of their licenses
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "licenses"
    And I use my auth token
    When I send a DELETE request to "/licenses/$2"
    Then the response status should be "204"
    And the current account should have 2 "licenses"

  Scenario: Admin attempts to delete a license for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the current account has 3 "licenses"
    And I use my auth token
    When I send a DELETE request to "/licenses/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "licenses"
