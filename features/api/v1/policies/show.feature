@api/v1
Feature: Show policy

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves a policy for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "policies"
    And I use my auth token
    When I send a GET request to "/policies/$0"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Product retrieves a policy for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "policy"
    And the current product has 1 "policy"
    When I send a GET request to "/policies/$0"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Product attempts to retrieve a policy for another product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "policy"
    When I send a GET request to "/policies/$0"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a policy for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the account "test1" has 3 "policies"
    And I use my auth token
    When I send a GET request to "/policies/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
