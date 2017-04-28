@api/v1
Feature: Delete product

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
    And the current account has 1 "product"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their products
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$2"
    Then the response status should be "204"
    And the current account should have 2 "products"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin attempts to delete a product for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 4 "webhookEndpoints"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "products"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product deletes itself
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$0"
    Then the response status should be "204"
    And the current account should have 2 "products"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product attempts to delete another product for their account
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$1"
    Then the response status should be "403"
    And the current account should have 3 "products"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
