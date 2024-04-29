@api/v1
Feature: Analytics of top licences by volume

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
    When I send a GET request to "/accounts/test1/analytics/actions/top-licenses-by-volume"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves analytics of top licenses by volume for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 50 "request-logs"
    And "request-logs" 0...15 have the following attributes:
      """
      {
        "resourceId": "bf9b523f-dd65-48a2-9512-fb66ba6c3714",
        "resourceType": "License"
      }
      """
    And "request-logs" 15...30 have the following attributes:
      """
      {
        "resourceId": "7559899f-2761-4b9c-a43e-2d919efa9b04",
        "resourceType": "User"
      }
      """
    And "request-logs" 30...50 have the following attributes:
      """
      {
        "resourceId": "a499bb93-9902-4b52-8a04-76944ad7f660",
        "resourceType": "License"
      }
      """
    And "request-logs" 0...10 have the following attributes:
      """
      {
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-licenses-by-volume"
    Then the response status should be "200"
    And the response body should contain meta with the following:
      """
      [
        {
          "licenseId": "a499bb93-9902-4b52-8a04-76944ad7f660",
          "count" : 20
        },
        {
          "licenseId": "bf9b523f-dd65-48a2-9512-fb66ba6c3714",
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
    When I send a GET request to "/accounts/test1/analytics/actions/top-licenses-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to retrieve analytic counts for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-licenses-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve analytics for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-licenses-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
