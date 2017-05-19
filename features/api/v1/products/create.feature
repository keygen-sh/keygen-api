@api/v1
Feature: Create product

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/products"
    Then the response status should be "403"

  Scenario: Admin creates a product for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 4 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin attempts to create an incomplete product for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to create a product for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Hello World App",
            "platforms": ["PC"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
