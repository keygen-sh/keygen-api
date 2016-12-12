@api/v1
Feature: Regenerate authentication token

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin resets their current token
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User resets their current token
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User resets their current token with a bad reset token
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Bearer someBadToken" }
      """
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "401"

  Scenario: Product resets their current token
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: Admin resets their token by id
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User resets their token by id
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token"

  Scenario: User resets their token by id with a bad reset token
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Bearer someBadToken" }
      """
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "401"

  Scenario: Product resets their token by id
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token"
