@api/v1
Feature: Account subscription

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin pauses their active account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "test1"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/pause"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "paused"
      }
      """

  Scenario: Admin pauses their active account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "test1"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/pause"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "paused"
      }
      """

  Scenario: Admin attempts to pause their paused account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "paused"
      }
      """
    And I am an admin of account "test1"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/pause"
    Then the response status should be "422"

  Scenario: Admin resumes their paused account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "paused"
      }
      """
    And I am an admin of account "test1"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/resume"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "active"
      }
      """

  Scenario: Admin attempts to resume their active account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "test1"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/resume"
    Then the response status should be "422"

  Scenario: Admin cancels their account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "test1"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/cancel"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "canceled"
      }
      """

  Scenario: Admin attempts to cancel their canceled account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "canceled"
      }
      """
    And I am an admin of account "test1"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/cancel"
    Then the response status should be "422"

  Scenario: Admin attempts to pause another account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "test2"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/pause"
    Then the response status should be "401"

  Scenario: Admin attempts to resume another account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "paused"
      }
      """
    And I am an admin of account "test2"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/resume"
    Then the response status should be "401"

  Scenario: Admin attempts to cancel another account
    Given the account "test1" has valid billing details
    And the account "test1" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "test2"
    And I use my authentication token
    When I send a POST request to "/accounts/$0/actions/cancel"
    Then the response status should be "401"
