@api/v1
Feature: User password actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/update-password"
    Then the response status should not be "403"

  Scenario: User updates their password
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "pass"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"

  Scenario: User updates their password by using their email
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      {
        "email": "user@example.com"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/user@example.com/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "pass"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"

  Scenario: User attempts to update password with missing parameters
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/update-password" with the following:
      """
      {
        "meta": {
          "newPassword": "pass"
        }
      }
      """
    Then the response status should be "400"

  Scenario: User of same account attempts to update password for another user
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$2/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "pass"
        }
      }
      """
    Then the response status should be "403"

  Scenario: User of another account attempts to update password for another user
    Given the current account is "test1"
    And the current account has 3 "users"
    And the account "test2" has 3 "users"
    And I am a user of account "test2"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$2/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "pass"
        }
      }
      """
    Then the response status should be "401"

  Scenario: Admin attempts to update password for another user
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$3/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "pass"
        }
      }
      """
    Then the response status should be "403"

  Scenario: User resets their password
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordResetToken": "$2a$10$AD.XND.9m50jyB14J9BFdOHkmJwVcYnjWKWcaObuR9yOLmn3WHuaS", "passwordResetSentAt": "$time.23.hours.ago" }
      """
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "password",
          "newPassword": "pass"
        }
      }
      """
    Then the response status should be "200"

  Scenario: User resets their password by using their email
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      {
        "passwordResetToken": "$2a$10$AD.XND.9m50jyB14J9BFdOHkmJwVcYnjWKWcaObuR9yOLmn3WHuaS",
        "passwordResetSentAt": "$time.23.hours.ago",
        "email": "user@example.com"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/user@example.com/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "password",
          "newPassword": "pass"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"

  Scenario: User attempts to reset password with missing parameters
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordResetToken": "$2a$10$AD.XND.9m50jyB14J9BFdOHkmJwVcYnjWKWcaObuR9yOLmn3WHuaS", "passwordResetSentAt": "$time.23.hours.ago" }
      """
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "newPassword": "pass"
        }
      }
      """
    Then the response status should be "400"

  Scenario: User attempts to reset their password with an expired token
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordResetToken": "$2a$10$AD.XND.9m50jyB14J9BFdOHkmJwVcYnjWKWcaObuR9yOLmn3WHuaS", "passwordResetSentAt": "$time.25.hours.ago" }
      """
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "password",
          "newPassword": "pass"
        }
      }
      """
    Then the response status should be "401"
