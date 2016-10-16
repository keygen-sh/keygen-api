@api/v1
Feature: Generate authentication token

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: User retrieve their tokens via basic authentication
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:password\"" }
      """
    When I send a GET request to "/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User attempts to retrieve their tokens but fails to authenticate
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[1].email:someBadPassword\"" }
      """
    When I send a GET request to "/tokens"
    Then the response status should be "401"

  Scenario: User attempts to retrieve their tokens without authentication
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    When I send a GET request to "/tokens"
    Then the response status should be "401"
