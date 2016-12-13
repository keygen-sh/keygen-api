@api/v1
Feature: Update account

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin updates their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the name "Company Name"

  Scenario: Admin updates the name for their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "new-name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the slug "new-name"

  Scenario: Admin attempts to update another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "401"

  Scenario: User attempts to update an account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "403"
