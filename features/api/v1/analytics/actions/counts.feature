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
    And the current account has 50 "licenses"
    And the current account has 30 "machines"
    # Adjust created timestamps so that some licenses are old
    And 25 "licenses" have the following attributes:
      """
      {
        "createdAt": "$time.1.year.ago"
      }
      """
    # Adjust validation timestamps so that some old licenses are still active
    And 20 "licenses" have the following attributes:
      """
      {
        "lastValidatedAt": "$time.1.day.ago"
      }
      """
    # Adjust associations so that some users own multiple liceness
    And 10 "licenses" have the following attributes:
      """
      {
        "userId": "$users[25]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/count"
    Then the response status should be "200"
    # FIXME(ezekg) The totals are a bit of a mess here because our factories
    #              create associated models instead of reusing the existing
    #              resource pool
    And the JSON response should contain meta with the following:
      """
      {
        "activeLicensedUsers": 66,
        "activeLicenses": 75,
        "totalLicenses": 80,
        "totalMachines": 30,
        "totalUsers": 131
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