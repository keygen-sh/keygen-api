@api/v1
Feature: Banned users

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Banned user attempts to authenticate with a token
    Given the current account is "test1"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "User is banned",
        "code": "USER_BANNED"
      }
      """

  Scenario: Banned user attempts to authenticate with a license key
    Given the current account is "test1"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "License is banned",
        "code": "LICENSE_BANNED"
      }
      """
