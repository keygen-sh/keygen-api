@api/v1
@ee
Feature: List request logs
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
    And the current account has 2 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "403"

  Scenario: Admin retrieves all logs for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "200"
    And the response body should be an array with 3 "request-logs"

  Scenario: Admin retrieves a list of logs that is automatically limited
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 250 "request-logs"
    And 50 "request-logs" have the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow"
    Then the response status should be "200"
    And the response body should be an array with 10 "request-logs"

  Scenario: Admin retrieves a list of logs with a limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 250 "request-logs"
    And 50 "request-logs" have the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow&limit=75"
    Then the response status should be "200"
    And the response body should be an array with 75 "request-logs"

  Scenario: Admin retrieves an unsupported paginated list of logs
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "request-logs"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/request-logs?page[number]=2&page[size]=5",
        "prev": "/v1/accounts/test1/request-logs?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/request-logs?page[number]=3&page[size]=5"
      }
      """

  Scenario: Admin retrieves a list of logs within a date range that's full
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow&limit=100"
    Then the response status should be "200"
    And the response body should be an array with 20 "request-logs"

  Scenario: Admin retrieves a list of logs within a date range that's empty
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=2017-1-2&date[end]=2017-01-03"
    Then the response status should be "200"
    And the response body should be an array with 0 "request-logs"

  Scenario: Admin retrieves a list of logs within a date range that's too far
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=2017-1-1&date[end]=2017-02-02"
    Then the response status should be "400"

  Scenario: Admin retrieves a list of logs within a date range that's invalid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=foo&date[end]=bar"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all logs for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Environment attempts to retrieve all isolated logs for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "request-logs"
    And the current account has 3 shared "request-logs"
    And the current account has 3 global "request-logs"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "request-logs"

  @ee
  Scenario: Environment attempts to retrieve all shared logs for their account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "request-logs"
    And the current account has 3 shared "request-logs"
    And the current account has 3 global "request-logs"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "request-logs"

  Scenario: Product attempts to retrieve all logs for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "request-logs"
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: License attempts to retrieve all logs for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 3 "request-logs"
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all logs for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "request-logs"
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "403"
    And the response body should be an array of 1 error
