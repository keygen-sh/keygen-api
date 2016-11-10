@api/v1
Feature: Create product

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin creates a product for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use an authentication token
    And the current account has 4 "webhookEndpoints"
    When I send a POST request to "/products" with the following:
      """
      { "product": { "name": "Cool App", "platforms": ["iOS", "Android"] } }
      """
    Then the response status should be "201"
    And sidekiq should have 4 "webhook" jobs

  Scenario: Admin attempts to create an incomplete product for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use an authentication token
    And the current account has 2 "webhookEndpoints"
    When I send a POST request to "/products" with the following:
      """
      { "product": { "platforms": ["iOS", "Android"] } }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to create a product for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use an authentication token
    And the current account has 1 "webhookEndpoint"
    When I send a POST request to "/products" with the following:
      """
      { "product": { "name": "Another Cool App" } }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Product attempts to create a product for their account
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhookEndpoint"
    When I send a POST request to "/products" with the following:
      """
      { "product": { "name": "Hello World App", "platforms": ["PC"] } }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
