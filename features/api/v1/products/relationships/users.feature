@api/v1
Feature: Product users

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin adds a user to a product
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/products/$0/relationships/users" with the following:
      """
      { "user": "$users[1]" }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Admin adds a user that doesn't exist to a product
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/products/$0/relationships/users" with the following:
      """
      { "user": "someUserId" }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to adds a user to a product for another account
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I use my auth token
    When I send a POST request to "/products/$0/relationships/users" with the following:
      """
      { "user": "$users[0]" }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin deletes a user from a product
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" is associated with the first "product"
    And I use my auth token
    When I send a DELETE request to "/products/$0/relationships/users/$1"
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job

  Scenario: Admin attempts to deletes a user from a product for another account
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" is associated with the first "product"
    And I use my auth token
    When I send a DELETE request to "/products/$0/relationships/users/$1"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
