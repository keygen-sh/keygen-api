@api/v1
Feature: Generate authentication token for product

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves a product's token
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And I use my authentication token
    When I send a GET request to "/products/$0/relationships/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: Product attempts to retrieve their token
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my authentication token
    When I send a GET request to "/products/$0/relationships/tokens"
    Then the response status should be "403"

  Scenario: Product attempts to retrieve another product's token
    Given I am on the subdomain "test1"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use my authentication token
    When I send a GET request to "/products/$1/relationships/tokens"
    Then the response status should be "403"

  Scenario: User attempts to retrieve a product's token
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my authentication token
    When I send a GET request to "/products/$0/relationships/tokens"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a product's token from another account
    Given I am an admin of account "test1"
    And I am on the subdomain "test2"
    And the current account has 1 "product"
    And I use my authentication token
    When I send a GET request to "/products/$0/relationships/tokens"
    Then the response status should be "401"
