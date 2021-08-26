@api/v1
Feature: Analytic counts

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/count"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves analytic counts for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 50 "users"
    And the current account has 50 userless "licenses"
    And the current account has 30 "machines" for existing "licenses"
    # Adjust created timestamps so that some licenses are old
    And "licenses" 0-25 have the following attributes:
      """
      {
        "createdAt": "$time.1.year.ago"
      }
      """
    # Adjust validation timestamps so that some old licenses are still active
    And "licenses" 0-20 have the following attributes:
      """
      {
        "lastValidatedAt": "$time.1.day.ago"
      }
      """
    # Adjust associations so that some users own multiple liceness
    And "licenses" 0-10 have the following attributes:
      """
      {
        "userId": "$users[2]"
      }
      """
    And the last "license" has the following attributes:
      """
      {
        "userId": "$users[42]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/count"
    Then the response status should be "200"
    # 50 users + 50 active unassigned licenses = 50 ALU
    # 50 ALU - 25 inactive unassigned licenses = 25 ALU
    # 25 ALU + 20 active unassigned licenses = 45 ACU
    # 45 ALU - 10 licenses assigned to user #2 = 36 ALU
    # 45 ALU - 1 license assigned to user #42 = 35 ALU
    And the JSON response should contain meta with the following:
      """
      {
        "activeLicensedUsers": 35,
        "activeLicenses": 45,
        "totalLicenses": 50,
        "totalMachines": 30,
        "totalUsers": 51
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve analytic counts for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/count"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
