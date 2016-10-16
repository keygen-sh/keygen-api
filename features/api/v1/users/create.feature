@api/v1
Feature: Create user

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
    And I send and accept JSON

  Scenario: Anonymous creates a user for an account
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    When I send a POST request to "/users" with the following:
      """
      { "user": { "name": "Superman", "email": "superman@keygin.io", "password": "lois" } }
      """
    Then the response status should be "201"
    And the JSON response should be a "user" with the name "Superman"
    And the current account should have 2 "users"
    And sidekiq should have 1 "webhook" job

  Scenario: Anonymous attempts to create an incomplete user for an account
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    When I send a POST request to "/users" with the following:
      """
      { "user": { "name": "Superman", "email": "superman@keygin.io" } }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 error

  Scenario: Admin creates an admin for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use my authentication token
    And the current account has 3 "webhookEndpoints"
    When I send a POST request to "/users" with the following:
      """
      {
        "user": {
          "name": "Ironman",
          "email": "ironman@keygin.io",
          "password": "jarvis",
          "roles": [{
            "name": "admin"
          }]
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 3 "webhook" jobs

  Scenario: User attempts to create an admin for their account
    Given I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my authentication token
    When I send a POST request to "/users" with the following:
      """
      {
        "user": {
          "name": "Superman",
          "email": "superman@keygin.io",
          "password": "sunlight",
          "roles": [{
            "name": "admin"
          }]
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Anonymous attempts to create an admin for an account
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    When I send a POST request to "/users" with the following:
      """
      {
        "user": {
          "name": "Thor",
          "email": "thor@keygin.io",
          "password": "mjolnir",
          "roles": [{
            "name": "admin"
          }]
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
