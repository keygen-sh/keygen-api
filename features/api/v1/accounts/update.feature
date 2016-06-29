@api/v1
Feature: Update account

  Scenario: Admin updates their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/accounts/eQ6Xobga" with the following:
      """
      { "account": { "name": "New Company Name" } }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the name "New Company Name"

  Scenario: Admin updates the subdomain for their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/accounts/eQ6Xobga" with the following:
      """
      { "account": { "subdomain": "new-domain" } }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the subdomain "new-domain"

  Scenario: Admin attempts to update another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And I am an admin of account "blizzard"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/accounts/eQ6Xobga" with the following:
      """
      { "account": { "name": "New Company Name" } }
      """
    Then the response status should be "401"

  Scenario: User attempts to update an account
    Given there exists an account "bungie"
    And the account "bungie" has 1 "user"
    And I am a user of account "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/accounts/eQ6Xobga" with the following:
      """
      { "account": { "name": "New Company Name" } }
      """
    Then the response status should be "403"
