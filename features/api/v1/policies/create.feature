@api/v1
Feature: Create policy

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin creates a policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "policy": {
          "name": "Premium Add-On",
          "price": 199,
          "product": "$products[0]",
          "maxMachines": 5,
          "floating": true,
          "strict": false,
          "encrypted": true,
          "duration": $time.2.weeks
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Admin attempts to create an incomplete policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "policy": {
          "name": "Basic",
          "price": 900,
          "maxMachines": 1,
          "floating": false,
          "strict": true,
          "duration": $time.2.weeks
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to create a policy that is encrypted and uses a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "policy": {
          "name": "Invalid",
          "product": "$products[0]",
          "encrypted": true,
          "usePool": true
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to create a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 7 "webhookEndpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "policy": {
          "name": "Basic",
          "price": 900,
          "product": "$products[0]",
          "maxMachines": 1,
          "floating": false,
          "strict": true,
          "duration": $time.2.weeks
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Product attempts to create a policy for their product
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "policy": {
          "name": "Basic",
          "price": 900,
          "product": "$products[0]",
          "maxMachines": 1,
          "floating": false,
          "strict": true,
          "encrypted": true,
          "duration": $time.2.weeks
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs

  Scenario: User attempts to create a policy for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "policy": {
          "name": "Basic",
          "price": 900,
          "product": "$products[0]",
          "maxMachines": 1,
          "floating": false,
          "strict": true,
          "duration": $time.2.weeks
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
