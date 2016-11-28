@api/v1
Feature: Revoke authentication token

  Background:
    Given the following "accounts" exist:
      | Company | Name  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin revokes one of their tokens
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a DELETE request to "/tokens/$0"
    Then the response status should be "204"

  Scenario: User revokes one of their tokens
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/tokens/$0"
    Then the response status should be "204"

  Scenario: Product revokes one of their tokens
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/tokens/$0"
    Then the response status should be "204"

  Scenario: Admin attempts to revoke another user's token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "users"
    And I use an authentication token
    When I send a DELETE request to "/tokens/$2"
    Then the response status should be "403"

  Scenario: User attempts to revoke another user's token
    Given the current account is "test1"
    And the current account has 5 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/tokens/$3"
    Then the response status should be "403"

  Scenario: Product attempts to revoke a user's token
    Given the current account is "test1"
    And the current account has 5 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/tokens/$4"
    Then the response status should be "403"
