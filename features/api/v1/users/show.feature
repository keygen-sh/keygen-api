@api/v1
Feature: Show user

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves a user for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "users"
    And I use my auth token
    When I send a GET request to "/users/$0"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Product retrieves a user for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "user"
    And the current product has 1 "user"
    When I send a GET request to "/users/$1"
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Product attempts to retrieve a user for another product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "user"
    When I send a GET request to "/users/$1"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a user for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use my auth token
    When I send a GET request to "/users/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
