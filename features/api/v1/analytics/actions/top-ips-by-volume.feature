@api/v1
Feature: Analytics of top IPs by volume

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
    When I send a GET request to "/accounts/test1/analytics/actions/top-ips-by-volume"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves analytics of top IPs by volume for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 50 "request-logs"
    And "request-logs" 1-15 have the following attributes:
      """
      {
        "ip": "192.168.1.1"
      }
      """
    And "request-logs" 16-30 have the following attributes:
      """
      {
        "ip": "192.168.0.1"
      }
      """
    And "request-logs" 31-50 have the following attributes:
      """
      {
        "ip": "2600:1700:3e90:a450:42d:239d:bf8d:2078"
      }
      """
    And "request-logs" 11-25 have the following attributes:
      """
      {
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-ips-by-volume"
    Then the response status should be "200"
    And the response body should contain meta with the following:
      """
      [
        {
          "ip": "2600:1700:3e90:a450:42d:239d:bf8d:2078",
          "count": 20
        },
        {
          "ip": "192.168.1.1",
          "count": 10
        },
        {
          "ip": "192.168.0.1",
          "count": 5
        }
      ]
      """
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve analytic counts for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/analytics/actions/top-ips-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to retrieve analytic counts for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-ips-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve analytics for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-ips-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
