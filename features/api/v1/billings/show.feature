@api/v1
Feature: Show billing info

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves the billing info for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use my auth token
    When I send a GET request to "/billing"
    Then the response status should be "200"
    And the JSON response should be a "billing"

  Scenario: Product attempts to retrieve the billing info for their account
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    When I send a GET request to "/billing"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the billing info for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use my auth token
    When I send a GET request to "/billing"
    Then the response status should be "401"
