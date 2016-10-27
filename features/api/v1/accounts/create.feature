@api/v1
Feature: Create account

  Background:
    And I send and accept JSON

  Scenario: Anonymous creates an account with a valid payment token
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "$plan[0]",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygen.sh", "password": "goog" }
          ]
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "account" with the name "Google"
    And the account "google" should have 1 "admin"

  Scenario: Anonymous creates an account with multiple admins
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "$plan[0]",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygen.sh", "password": "goog" },
            { "name": "Sergey Brin", "email": "sbrin@keygen.sh", "password": "goog" },
            { "name": "Sundar Pichai", "email": "spichai@keygen.sh", "password": "goog" }
          ]
        }
      }
      """
    Then the response status should be "201"
    And the account "google" should have 3 "admins"

  Scenario: Anonymous attempts to create an account without a plan
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygen.sh", "password": "goog" }
          ]
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 error

  Scenario: Anonymous attempts to create an account without any admin users
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "$plan[0]"
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 errors

  Scenario: Anonymous attempts to create a duplicate account
    Given there exists an account "test1"
    And there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "test1",
          "name": "Test1",
          "plan": "$plan[0]",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygen.sh", "password": "goog" }
          ]
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 errors

  Scenario: Anonymous attempts to use a reserved subdomain
    Given there exists an account "test1"
    And there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "test",
          "name": "Facebook",
          "plan": "$plan[0]",
          "admins": [
            { "name": "Mark Zuckerburg", "email": "mzuckerberk@keygen.sh", "password": "facebook" }
          ]
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 errors
