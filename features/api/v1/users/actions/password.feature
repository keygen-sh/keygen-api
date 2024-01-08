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
    And the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/update-password"
    Then the response status should not be "403"

  # Update
  Scenario: User updates their password
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "tokens" for the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "password2"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the current user should have 1 "token"

  Scenario: User updates their password (no password set)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "passwordDigest": null }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "password2"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "401"

  Scenario: User updates their password (too short)
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
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
          "title": "Unprocessable resource",
          "detail": "is too short (minimum is 6 characters)",
          "source": {
            "pointer": "/data/attributes/password"
          },
          "code": "PASSWORD_TOO_SHORT"
        }
      """

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
          "newPassword": "password2"
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
          "newPassword": "password2"
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
          "newPassword": "password2"
        }
      }
      """
    Then the response status should be "404"

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
          "newPassword": "password2"
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
          "newPassword": "password2"
        }
      }
      """
    Then the response status should be "403"

  Scenario: Read only updates their password
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "password2"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"

  Scenario: License attempts to updates their user's password
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "password2"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"

  Scenario: License attempts to updates a user's password
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/update-password" with the following:
      """
      {
        "meta": {
          "oldPassword": "password",
          "newPassword": "password2"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "404"

  # Reset
  Scenario: User resets their password
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "tokens" for the last "user"
    And I am a user of account "test1"
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/$1/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "password2"
        }
      }
      """
    Then the response status should be "200"
    And the current user should have 0 "tokens"

  Scenario: User resets their password by using their email
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "email": "user@example.com" }
      """
    And I use an authentication token
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/user@example.com/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "password2"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"

  Scenario: User resets their password (unprotected, no password set)
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordDigest": null }
      """
    And I use an authentication token
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "bd2e5b3410e5"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"

  Scenario: User resets their password (protected, no password set)
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordDigest": null }
      """
    And I use an authentication token
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "bd2e5b3410e5"
        }
      }
      """
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin resets their password (protected, no password set)
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And I am an admin of account "test1"
    And I have the following attributes:
      """
      { "passwordDigest": null }
      """
    And I use an authentication token
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "bd2e5b3410e5"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"

  Scenario: User resets their password (too short)
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "email": "user@example.com" }
      """
    And I use an authentication token
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "bad"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
          "title": "Unprocessable resource",
          "detail": "is too short (minimum is 6 characters)",
          "source": {
            "pointer": "/data/attributes/password"
          },
          "code": "PASSWORD_TOO_SHORT"
        }
      """

  Scenario: User attempts to reset password with missing parameters
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "newPassword": "password2"
        }
      }
      """
    Then the response status should be "400"

  Scenario: User attempts to reset their password with an expired token
    Given the current account is "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have a password reset token that is expired
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "password2"
        }
      }
      """
    Then the response status should be "401"

  Scenario: Read only updates their password
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I have a password reset token
    When I send a POST request to "/accounts/test1/users/$current/actions/reset-password" with the following:
      """
      {
        "meta": {
          "passwordResetToken": "$token",
          "newPassword": "password2"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
