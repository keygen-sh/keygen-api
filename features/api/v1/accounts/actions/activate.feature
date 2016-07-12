@api/v1
Feature: Account activation

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
    And I send and accept JSON

  Scenario: Anonymous activates an account
    Given the account "test1" is not activated
    When I send a POST request to "/accounts/$0/actions/activate" with the following:
      """
      { "activationToken": "$account[0].activation_token" }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" that is activated

  Scenario: Anonymous uses an invalid activation token
    Given the account "test1" is not activated
    When I send a POST request to "/accounts/$0/actions/activate" with the following:
      """
      { "activationToken": "some_invalid_token" }
      """
    Then the response status should be "422"
