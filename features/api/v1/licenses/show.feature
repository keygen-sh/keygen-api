@api/v1
Feature: Show license

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves a license for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "licenses"
    And I use my auth token
    When I send a GET request to "/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"

  Scenario: Admin attempts to retrieve a license for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the account "test1" has 3 "licenses"
    And I use my auth token
    When I send a GET request to "/licenses/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
