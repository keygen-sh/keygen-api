@api/v1
Feature: Account subscription

  Scenario: Admin pauses their active account
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/pause"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "paused"
      }
      """

  Scenario: Admin attempts to pause their paused account
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "paused"
      }
      """
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/pause"
    Then the response status should be "422"

  Scenario: Admin resumes their paused account
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "paused"
      }
      """
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/resume"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "active"
      }
      """

  Scenario: Admin attempts to resume their active account
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/resume"
    Then the response status should be "422"

  Scenario: Admin cancels their account
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/cancel"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "canceled"
      }
      """

  Scenario: Admin attempts to cancel their canceled account
    Given there exists an account "bungie"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "canceled"
      }
      """
    And I am an admin of account "bungie"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/cancel"
    Then the response status should be "422"

  Scenario: Admin attempts to pause another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "blizzard"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/pause"
    Then the response status should be "401"

  Scenario: Admin attempts to resume another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "paused"
      }
      """
    And I am an admin of account "blizzard"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/resume"
    Then the response status should be "401"

  Scenario: Admin attempts to cancel another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And the account "bungie" has valid billing details
    And the account "bungie" has the following attributes:
      """
      {
        "status": "active"
      }
      """
    And I am an admin of account "blizzard"
    And I use my auth token
    And I send and accept JSON
    When I send a POST request to "/accounts/eQ6Xobga/actions/cancel"
    Then the response status should be "401"
