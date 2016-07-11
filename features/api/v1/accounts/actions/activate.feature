@api/v1
Feature: Account activation

  Scenario: Anonymous activates an account
    Given there exists an account "bungie"
    And the account "bungie" is not activated
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/activate" with the following:
      """
      { "activationToken": "${ACCOUNT.ACTIVATION_TOKEN}" }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" that is activated

    Scenario: Anonymous uses an invalid activation token
      Given there exists an account "bungie"
      And the account "bungie" is not activated
      And I send and accept JSON
      When I send a POST request to "/accounts/eQ6Xobga/actions/activate" with the following:
        """
        { "activationToken": "some_invalid_token" }
        """
      Then the response status should be "422"
