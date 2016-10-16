@api/v1
Feature: Update account

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin updates their account
    Given I am an admin of account "test1"
    And I use my authentication token
    When I send a PATCH request to "/accounts/$0" with the following:
      """
      { "account": { "name": "New Company Name" } }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the name "New Company Name"

  Scenario: Admin updates the subdomain for their account
    Given I am an admin of account "test1"
    And I use my authentication token
    When I send a PATCH request to "/accounts/$0" with the following:
      """
      { "account": { "subdomain": "new-domain" } }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the subdomain "new-domain"

  Scenario: Admin attempts to update another account
    Given I am an admin of account "test2"
    And I use my authentication token
    When I send a PATCH request to "/accounts/$0" with the following:
      """
      { "account": { "name": "New Company Name" } }
      """
    Then the response status should be "401"

  Scenario: User attempts to update an account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use my authentication token
    When I send a PATCH request to "/accounts/$0" with the following:
      """
      { "account": { "name": "New Company Name" } }
      """
    Then the response status should be "403"
