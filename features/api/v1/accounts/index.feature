@api/v1
Feature: List accounts

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin attempts to retrieve all accounts
    Given I am an admin of account "test2"
    And I use my auth token
    When I send a GET request to "/accounts"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all accounts
    Given the account "test2" has 3 "users"
    And I am a user of account "test2"
    And I use my auth token
    When I send a GET request to "/accounts"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error

  Scenario: Anonymous attempts to retrieve all accounts
    When I send a GET request to "/accounts"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
