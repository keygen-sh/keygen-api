@api/v1
Feature: List users

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves all users for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "users"
    And I use my auth token
    When I send a GET request to "/users"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "users"

  Scenario: Admin attempts to retrieve all users for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use my auth token
    When I send a GET request to "/users"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
