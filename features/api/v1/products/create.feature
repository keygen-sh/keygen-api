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
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with a LICENSED distribution strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "distributionStrategy": "LICENSED"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "product" with the distributionStrategy "LICENSED"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with a OPEN distribution strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "distributionStrategy": "OPEN"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "product" with the distributionStrategy "OPEN"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with a CLOSED distribution strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "distributionStrategy": "CLOSED"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "product" with the distributionStrategy "CLOSED"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a product with an invalid URL for their account
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
            "url": "file:///boom.sh",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a product for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Read-only attempts to create a product for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/products" with the following:
      """
      {
        "data": {
          "type": "products",
          "attributes": {
            "name": "Cool App",
            "url": "http://example.com",
            "platforms": ["iOS", "Android"]
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job
