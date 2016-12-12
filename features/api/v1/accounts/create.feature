@api/v1
Feature: Create account

  Background:
    Given I send and accept JSON

  Scenario: Anonymous creates an account
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "name": "Google",
          "slug": "google",
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

  # NOTE: This is really just a test to make sure endpoints are valid even when
  #       we're authenticated as another account
  Scenario: Admin of an account creates another account
    Given the following "accounts" exist:
      | Name      | Slug      |
      | Hashicorp | hashicorp |
    And there exists 1 "plan"
    And I am an admin of account "hashicorp"
    And I use an authentication token
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "name": "Google",
          "slug": "google",
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
          "name": "Google",
          "slug": "google",
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

  Scenario: Anonymous creates an account with multiple admins and an invalid parameter
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "name": "Google",
          "slug": "google",
          "plan": "$plan[0]",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygen.sh", "password": "goog" },
            { "name": "Sergey Brin", "email": "sbrin@keygen.sh", "password": "goog" },
            { "name": "Sundar Pichai", "email": "spichai@keygen.sh", "password": "goog" },
            "someInvalidParam"
          ]
        }
      }
      """
    Then the response status should be "400"

  Scenario: Anonymous attempts to create an account without a plan
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "name": "Google",
          "slug": "google",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygen.sh", "password": "goog" }
          ]
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error

  Scenario: Anonymous attempts to create an account without any admin users
    Given there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "name": "Google",
          "slug": "google",
          "plan": "$plan[0]"
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 errors

  Scenario: Anonymous attempts to create a duplicate account
    Given there exists an account "test1"
    And there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "name": "Test1",
          "slug": "test1",
          "plan": "$plan[0]",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygen.sh", "password": "goog" }
          ]
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 errors
