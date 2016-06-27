@api/v1
Feature: Create user

  Scenario: Anonymous creates a user for an account
    Given there exists an account "bungie"
    And I am on the subdomain "bungie"
    And I send and accept JSON
    And I have 1 "user"
    When I send a POST request to "/users" with the following:
      """
      { "user": { "name": "Superman", "email": "superman@keygin.io", "password": "lois" } }
      """
    Then the response status should be "201"
    And the JSON response should be a "user" with the name "Superman"
    And I should have 2 "users"

  Scenario: Admin creates an admin for their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a POST request to "/users" with the following:
      """
      { "user": { "name": "Ironman", "email": "ironman@keygin.io", "password": "jarvis", "role": "admin" } }
      """
    Then the response status should be "201"

  Scenario: Anonymous attempts to create an admin for an account
    Given there exists an account "bungie"
    And I am on the subdomain "bungie"
    And I send and accept JSON
    When I send a POST request to "/users" with the following:
      """
      { "user": { "name": "Thor", "email": "thor@keygin.io", "password": "mjolnir", "role": "admin" } }
      """
    Then the response status should be "400"
