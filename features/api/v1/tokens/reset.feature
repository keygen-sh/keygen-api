@api/v1
Feature: Reset tokens

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: User resets their tokens
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my reset token
    When I send a POST request to "/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User resets their tokens with a bad reset token
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/tokens"
    Then the response status should be "401"

  Scenario: Product resets their tokens
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my reset token
    When I send a POST request to "/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token"
