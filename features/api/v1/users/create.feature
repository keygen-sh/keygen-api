@api/v1
Feature: Create user

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Anonymous creates a user for an account
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "name": "Superman",
            "email": "superman@keygen.sh",
            "password": "lois"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "user" with the name "Superman"
    And the current account should have 2 "users"
    And sidekiq should have 1 "webhook" job

  Scenario: Anonymous attempts to create an incomplete user for an account
    Given the current account is "test1"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "name": "Superman",
            "email": "superman@keygen.sh"
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error

  Scenario: Anonymous attempts to create a user with invalid parameter types
    Given the current account is "test1"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "name": "Superman",
            "email": 42,
            "password": "lois"
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error

  Scenario: Admin creates an admin for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 3 "webhookEndpoints"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "name": "Ironman",
            "email": "ironman@keygen.sh",
            "password": "jarvis"
          },
          "relationships": {
            "role": {
              "name": "admin"
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 3 "webhook" jobs

  Scenario: Admin attempts to create a user with an invalid role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 3 "webhookEndpoints"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "name": "Spiderman",
            "email": "spiderman@keygen.sh",
            "password": "web"
          },
          "relationships": {
            "role": {
              "name": "spider"
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs

  Scenario: User attempts to create an admin for their account
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "name": "Superman",
            "email": "superman@keygen.sh",
            "password": "sunlight"
          },
          "relationships": {
            "role": {
              "name": "admin"
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Anonymous attempts to create an admin for an account
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "name": "Thor",
            "email": "thor@keygen.sh",
            "password": "mjolnir"
          },
          "relationships": {
            "role": {
              "name": "admin"
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
