@api/v1
Feature: Update billing info

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin updates the billing info for their account
    Given the account "test1" has valid billing details
    And I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use my authentication token
    And I have a valid payment token
    When I send a POST request to "/billing" with the following:
      """
      { "billing": { "token": "some_token" } }
      """
    Then the response status should be "202"

  Scenario: Product attempts to update the billing info for their account
    Given the account "test1" has valid billing details
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my authentication token
    And I have a valid payment token
    When I send a POST request to "/billing" with the following:
      """
      { "billing": { "token": "some_token" } }
      """
    Then the response status should be "403"

  Scenario: Admin attempts to update the billing info for another account
    Given the account "test1" has valid billing details
    And I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use my authentication token
    And I have a valid payment token
    When I send a POST request to "/billing" with the following:
      """
      { "billing": { "token": "some_token" } }
      """
    Then the response status should be "401"
