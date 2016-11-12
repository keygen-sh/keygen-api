@api/v1
Feature: List policies

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves all policies for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/policies"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "policies"

  Scenario: Admin retrieves all policies without a limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/policies"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "policies"

  Scenario: Admin retrieves all policies with a low limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 10 "policies"
    And I use an authentication token
    When I send a GET request to "/policies?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "policies"

  Scenario: Admin retrieves all policies with a high limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/policies?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "policies"

  Scenario: Admin retrieves all policies with a limit that is too high
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/policies?limit=900"
    Then the response status should be "400"

  Scenario: Product retrieves all policies for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "policies"
    And the current product has 1 "policy"
    When I send a GET request to "/policies"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "policy"

  Scenario: Admin attempts to retrieve all policies for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use an authentication token
    When I send a GET request to "/policies"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all policies for their account
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "policies"
    When I send a GET request to "/policies"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
