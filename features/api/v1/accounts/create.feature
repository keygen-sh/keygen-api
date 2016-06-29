@api/v1
Feature: Create account

  Scenario: Anonymous creates an account with a valid payment token
    Given I send and accept JSON
    And there exists 1 "plan"
    And I have a valid payment token
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "ElZw7Zko",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygin.io", "password": "goog" }
          ],
          "billing": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "account" with the name "Google"

  Scenario: Anonymous creates an account with a card declined payment token error
    Given I send and accept JSON
    And there exists 1 "plan"
    And I have a payment token with a "card declined" error
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "ElZw7Zko",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygin.io", "password": "goog" }
          ],
          "billing": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 2 errors

  Scenario: Anonymous creates an account with missing payment token error
    Given I send and accept JSON
    And there exists 1 "plan"
    And I have a payment token with a "missing" error
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "ElZw7Zko",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygin.io", "password": "goog" }
          ],
          "billing": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 2 errors

  Scenario: Anonymous attempts to create an account without a plan
    Given I send and accept JSON
    And there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygin.io", "password": "goog" }
          ],
          "billing": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 error

  Scenario: Anonymous attempts to create an account without billing info
    Given I send and accept JSON
    And there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "ElZw7Zko",
          "admins": [
            { "name": "Larry Page", "email": "lpage@keygin.io", "password": "goog" }
          ]
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 2 errors

  Scenario: Anonymous attempts to create an account without any admin users
    Given I send and accept JSON
    And there exists 1 "plan"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "account": {
          "subdomain": "google",
          "name": "Google",
          "plan": "ElZw7Zko",
          "billing": {
            "token": "some_token"
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 errors
