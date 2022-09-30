@api/v1
Feature: Regenerate authentication token

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
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "403"

  Scenario: Admin resets their current token
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 2 "webhook-endpoints"
    And I use an authentication token
    And the current token has the following attributes:
      """
      { "expiry": null }
      """
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "admin-token",
        "expiry": null
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User resets their current token
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      { "expiry": "$time.1.week.from_now.iso" }
      """
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a kind "user-token"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now.iso"
    And the JSON response should be a "token" with a token

  Scenario: User resets their current token that is expired
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      { "expiry": "$time.1.week.ago.iso" }
      """
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "401"

  Scenario: User resets their current token with a bad reset token
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Bearer someBadToken" }
      """
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "TOKEN_INVALID"
      }
      """

  Scenario: Product resets their current token
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      { "expiry": null }
      """
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a token
    And the JSON response should be a "token" with the following attributes:
      """
      {
        "kind": "product-token",
        "expiry": null
      }
      """

  Scenario: License resets their current token
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      { "expiry": "2050-01-01T00:00:00.000Z" }
      """
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be a "token" with a kind "activation-token"
    And the JSON response should be a "token" with an expiry within seconds of "$time.2.weeks.from_now.iso"
    And the JSON response should be a "token" with a token

  Scenario: Admin resets their token by id
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token" with a token

  Scenario: User resets their token by id
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token" with a token

  Scenario: User resets their token by id with a bad reset token
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "token" for the last "user"
    And I am a user of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Bearer someBadToken" }
      """
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "401"

  Scenario: Product resets their token by id
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the JSON response should be a "token" with a token

  Scenario: License resets their current token while authenticating with a license key
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
    And I authenticate with my license key
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "404"
