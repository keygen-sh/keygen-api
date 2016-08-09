@api/v1
Feature: Update product

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin updates a product for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And I use my auth token
    When I send a PATCH request to "/products/$0" with the following:
      """
      { "product": { "name": "New App" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "product" with the name "New App"

  Scenario: Admin attempts to update a product for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the account "test1" has 1 "product"
    And I use my auth token
    When I send a PATCH request to "/products/$0" with the following:
      """
      { "product": { "name": "Updated App" } }
      """
    Then the response status should be "401"

  Scenario: Admin updates a product's platforms for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "products"
    And I use my auth token
    When I send a PATCH request to "/products/$1" with the following:
      """
      { "product": { "platforms": ["iOS", "Android", "Windows"] } }
      """
    Then the response status should be "200"
    And the JSON response should be a "product" with the following platforms:
      """
      [
        "iOS",
        "Android",
        "Windows"
      ]
      """
