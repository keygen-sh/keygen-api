@api/v1
Feature: Account billing info

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves the billing info for their account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "200"
    And the JSON response should be a "billing"

  Scenario: Product attempts to retrieve the billing info for their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the billing info for another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/billing"
    Then the response status should be "401"

  Scenario: Admin updates the billing info for their account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      { "token": "some_token" }
      """
    Then the response status should be "202"

  Scenario: Product attempts to update the billing info for their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      { "token": "some_token" }
      """
    Then the response status should be "403"

  Scenario: Admin attempts to update the billing info for another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And I use an authentication token
    And I have a valid payment token
    When I send a PATCH request to "/accounts/test1/billing" with the following:
      """
      { "token": "some_token" }
      """
    Then the response status should be "401"
