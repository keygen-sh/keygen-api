@api/v1
Feature: Request limits

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is subscribed and has exceeded its daily request limit
    Given the account "test1" has exceeded its daily request limit
    And the account "test1" is subscribed
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should not be "402"

  Scenario: Endpoint should be inaccessible when account is trialing and has exceeded its daily request limit
    Given the account "test1" has exceeded its daily request limit
    And the current account is "test1"
    And the account "test1" does not have a card on file
    And the account "test1" is trialing
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should be "402"

  Scenario: Endpoint should be accessible when account is trialing and has exceeded its daily request limit but has a card on file
    Given the account "test1" has exceeded its daily request limit
    And the current account is "test1"
    And the account "test1" does have a card on file
    And the account "test1" is trialing
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should not be "402"

  Scenario: Endpoint should be accessible when account is trialing and has exceeded its daily request limit but the request came from the dashboard
    Given the account "test1" has exceeded its daily request limit
    And the current account is "test1"
    And the account "test1" does not have a card on file
    And the account "test1" is trialing
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Origin": "https://app.keygen.sh" }
      """
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should not be "402"

  Scenario: Endpoint should be inaccessible when account is on a free tier and has exceeded its daily request limit
    Given the account "test1" has exceeded its daily request limit
    And the account "test1" is subscribed
    And the account "test1" is on a free tier
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should be "402"

  Scenario: Endpoint should be accessible when account is on a free tier and has exceeded its daily request limit but the request came from the dashboard
    Given the account "test1" has exceeded its daily request limit
    And the account "test1" is subscribed
    And the account "test1" is on a free tier
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Origin": "https://app.keygen.sh" }
      """
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should not be "402"
