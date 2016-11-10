@api/v1
Feature: Show product

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves a product for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a GET request to "/products/$0"
    Then the response status should be "200"
    And the JSON response should be a "product"

  Scenario: Admin attempts to retrieve a product for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the account "test1" has 3 "products"
    And I use an authentication token
    When I send a GET request to "/products/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: Product retrieves itself
    Given I am on the subdomain "test1"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/products/$0"
    Then the response status should be "200"
    And the JSON response should be a "product"

  Scenario: Product attempts to retrieve another product
    Given I am on the subdomain "test1"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/products/$1"
    Then the response status should be "403"
