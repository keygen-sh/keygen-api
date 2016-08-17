@api/v1
Feature: User password

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: User updates their password
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/users/$current/actions/update-password" with the following:
      """
      { "oldPassword": "password", "newPassword": "pass" }
      """
    Then the response status should be "200"

  Scenario: User attempts to update password with missing parameters
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/users/$current/actions/update-password" with the following:
      """
      { "newPassword": "pass" }
      """
    Then the response status should be "400"

  Scenario: User of same account attempts to update password for another user
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/users/$3/actions/update-password" with the following:
      """
      { "oldPassword": "password", "newPassword": "pass" }
      """
    Then the response status should be "403"

  Scenario: User of another account attempts to update password for another user
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And the account "test2" has 3 "users"
    And I am a user of account "test2"
    And I use my auth token
    When I send a POST request to "/users/$2/actions/update-password" with the following:
      """
      { "oldPassword": "password", "newPassword": "pass" }
      """
    Then the response status should be "401"

  Scenario: Admin attempts to update password for another user
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And I am an admin of account "test1"
    And I use my auth token
    When I send a POST request to "/users/$3/actions/update-password" with the following:
      """
      { "oldPassword": "password", "newPassword": "pass" }
      """
    Then the response status should be "403"

  Scenario: User resets their password
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordResetToken": "token", "passwordResetSentAt": "$time.23.hours.ago" }
      """
    And I use my auth token
    When I send a POST request to "/users/$current/actions/reset-password" with the following:
      """
      { "passwordResetToken": "$current.password_reset_token", "newPassword": "pass" }
      """
    Then the response status should be "200"

  Scenario: User attempts to reset password with missing parameters
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordResetToken": "token", "passwordResetSentAt": "$time.23.hours.ago" }
      """
    And I use my auth token
    When I send a POST request to "/users/$current/actions/reset-password" with the following:
      """
      { "newPassword": "pass" }
      """
    Then the response status should be "400"

  Scenario: User attempts to reset their password with an expired token
    Given I am on the subdomain "test1"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I have the following attributes:
      """
      { "passwordResetToken": "token", "passwordResetSentAt": "$time.25.hours.ago" }
      """
    And I use my auth token
    When I send a POST request to "/users/$current/actions/reset-password" with the following:
      """
      { "passwordResetToken": "$current.password_reset_token", "newPassword": "pass" }
      """
    Then the response status should be "401"
