@api/v1
Feature: Create product

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin creates a product for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use my auth token
    When I send a POST request to "/products" with the following:
      """
      { "product": { "name": "Cool App", "platforms": ["iOS", "Android"] } }
      """
    Then the response status should be "201"

  Scenario: Admin attempts to create an incomplete product for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use my auth token
    When I send a POST request to "/products" with the following:
      """
      { "product": { "platforms": ["iOS", "Android"] } }
      """
    Then the response status should be "422"

  Scenario: Admin attempts to create a product for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use my auth token
    When I send a POST request to "/products" with the following:
      """
      { "product": { "name": "Another Cool App" } }
      """
    Then the response status should be "401"
