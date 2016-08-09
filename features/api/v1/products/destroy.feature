@api/v1
Feature: Delete product

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin deletes one of their products
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "products"
    And I use my auth token
    When I send a DELETE request to "/products/$2"
    Then the response status should be "204"
    And the current account should have 2 "products"

  Scenario: Admin attempts to delete a product for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the current account has 3 "products"
    And I use my auth token
    When I send a DELETE request to "/products/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "products"
