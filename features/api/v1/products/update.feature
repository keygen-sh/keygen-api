@api/v1
Feature: Update product

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin updates a product for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a PATCH request to "/products/$0" with the following:
      """
      { "product": { "name": "New App" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "product" with the name "New App"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Admin attempts to update a product for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the account "test1" has 1 "product"
    And I use an authentication token
    When I send a PATCH request to "/products/$0" with the following:
      """
      { "product": { "name": "Updated App" } }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin updates a product's platforms for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "webhookEndpoints"
    And the current account has 2 "products"
    And I use an authentication token
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
    And sidekiq should have 3 "webhook" jobs

  Scenario: Product updates the platforms for itself
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/products/$0" with the following:
      """
      { "product": { "platforms": ["Nintendo"] } }
      """
    Then the response status should be "200"
    And the JSON response should be a "product" with the following platforms:
      """
      ["Nintendo"]
      """
    And sidekiq should have 1 "webhook" job

  Scenario: Product attempts to update the platforms for another product
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/products/$1" with the following:
      """
      { "product": { "platforms": ["PC"] } }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
