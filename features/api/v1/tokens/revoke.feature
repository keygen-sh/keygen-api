@api/v1
Feature: Revoke authentication token

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should not be "403"

  Scenario: Admin revokes one of their tokens
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User revokes one of their tokens
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment revokes one of their tokens
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0?environment=shared"
    Then the response status should be "204"

  Scenario: Product revokes one of their tokens
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"

  Scenario: Admin revokes another user's token
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$2"
    Then the response status should be "204"

  Scenario: User attempts to revoke another user's token
    Given the current account is "test1"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$3"
    Then the response status should be "404"

  Scenario: Product revokes a token for an admin
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "admin"
    And the current account has 1 "token" for the last "admin"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "404"

  Scenario: Product revokes a token for their user
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "token" for the last "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"

  Scenario: Product revokes a token for a user
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "token" for the last "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "404"

  Scenario: Product revokes a token for their license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "token" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"

  Scenario: Product revokes a token for a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 1 "token" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "404"
