@api/v1
Feature: Product users

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin adds a user to a product
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/products/$0/relationships/users" with the following:
      """
      { "user": "$users[0]" }
      """
    Then the response status should be "201"

  Scenario: Admin adds a user that doesn't exist to a product
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/products/$0/relationships/users" with the following:
      """
      { "user": "someUserId" }
      """
    Then the response status should be "422"

  Scenario: Admin attempts to adds a user to a product for another account
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the account "test1" has 1 "product"
    And the account "test1" has 1 "user"
    And I use my auth token
    When I send a POST request to "/products/$0/relationships/users" with the following:
      """
      { "user": "$users[0]" }
      """
    Then the response status should be "401"

  Scenario: Admin deletes a user from a product
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I use my auth token
    When I send a DELETE request to "/products/$0/relationships/users/$0"
    Then the response status should be "204"

  Scenario: Admin attempts to deletes a user from a product for another account
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the account "test1" has 1 "product"
    And the account "test1" has 1 "user"
    And I use my auth token
    When I send a DELETE request to "/products/$0/relationships/users/$0"
    Then the response status should be "401"
