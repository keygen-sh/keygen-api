@api/v1
Feature: License permits

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin renews a license
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "duration": $time.1.month
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": $policies[0].id,
        "expiry": "2016-09-05T22:53:37.000Z"
      }
      """
    And I use an authentication token
    When I send a POST request to "/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job

  Scenario: User renews their license
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "duration": $time.1.month
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": $policies[0].id,
        "expiry": "2016-12-01T22:53:37.000Z"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-12-31T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job

  Scenario: Admin attempts to renew a license for another account
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/licenses/$0/actions/renew"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin revokes a license
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a POST request to "/licenses/$0/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job

  Scenario: User revokes their own license
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I am a user of account "test1"
    And the current user has 2 "licenses"
    And I use an authentication token
    When I send a POST request to "/licenses/$0/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job

  Scenario: User tries to revoke another user's license
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/licenses/$0/actions/revoke"
    Then the response status should be "403"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin tries to revoke a license for another account
    Given I am an admin of account "test1"
    And I am on the subdomain "test2"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a POST request to "/licenses/$0/actions/revoke"
    Then the response status should be "401"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
