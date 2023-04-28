@api/v1
Feature: Analytics of top URLs by volume

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
    When I send a GET request to "/accounts/test1/analytics/actions/top-urls-by-volume"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves analytics of top URLs by volume for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 100 "request-logs"
    And "request-logs" 1-50 have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses/actions/validate-key",
        "method": "POST"
      }
      """
    And "request-logs" 51-80 have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/machines",
        "method": "POST"
      }
      """
    And "request-logs" 81-90 have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses",
        "method": "POST"
      }
      """
    And "request-logs" 91-95 have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses/ed65c9d0-4765-4f1a-8632-9865a4d99d19",
        "method": "GET"
      }
      """
    And "request-logs" 96-98 have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses/65ee222a-d5f6-425b-88a3-ae83a9c51bcc",
        "method": "PATCH"
      }
      """
    And "request-logs" 99-100 have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses/bf9b523f-dd65-48a2-9512-fb66ba6c3714",
        "method": "GET"
      }
      """
    And "request-logs" 1-15 have the following attributes:
      """
      {
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-urls-by-volume"
    Then the response status should be "200"
    And the response body should contain meta with the following:
      """
      [
        {
          "url": "/v1/accounts/test1/licenses/actions/validate-key",
          "method": "POST",
          "count": 35
        },
        {
          "url": "/v1/accounts/test1/machines",
          "method": "POST",
          "count": 30
        },
        {
          "url": "/v1/accounts/test1/licenses",
          "method": "POST",
          "count": 10
        },
        {
          "url": "/v1/accounts/test1/licenses/ed65c9d0-4765-4f1a-8632-9865a4d99d19",
          "method": "GET",
          "count": 5
        },
        {
          "url": "/v1/accounts/test1/licenses/65ee222a-d5f6-425b-88a3-ae83a9c51bcc",
          "method": "PATCH",
          "count": 3
        },
        {
          "url": "/v1/accounts/test1/licenses/bf9b523f-dd65-48a2-9512-fb66ba6c3714",
          "method": "GET",
          "count": 2
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
    When I send a GET request to "/accounts/test1/analytics/actions/top-urls-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to retrieve analytic counts for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-urls-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve analytics for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/analytics/actions/top-urls-by-volume"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
