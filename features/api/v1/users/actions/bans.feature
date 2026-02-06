@api/v1
Feature: User ban actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should not be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$current/actions/ban"
    Then the response status should be "403"

  # Ban
  Scenario: Admin bans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "BANNED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin bans another admin
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "admins"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin bans themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"

  @ee
  Scenario: Environment bans an isolated user
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "user"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "BANNED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment bans a shared user
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "user"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "BANNED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment bans a global user
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "user"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product bans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "BANNED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: License bans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "404"

  Scenario: License bans themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"

  Scenario: User bans another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 2 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$2/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "404"

  Scenario: User bans themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"

  Scenario: Anonymous bans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "401"

  # Unban
  Scenario: Admin unbans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "ACTIVE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment unbans an isolated user
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "user" with the following:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "ACTIVE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment unbans a shared user
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "user" with the following:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "ACTIVE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment unbans a global user
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "user" with the following:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product unbans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      { "status": "ACTIVE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: License bans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/ban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "404"

  Scenario: License unbans themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
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
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"

  Scenario: User unbans another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 2 "users"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$2/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "404"

  Scenario: User unbans themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"

  Scenario: Anonymous unbans a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    When I send a POST request to "/accounts/test1/users/$1/actions/unban"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "401"
