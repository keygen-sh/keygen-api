@api/v1
Feature: License permit actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin renews a license
    Given I am an admin of account "test1"
    And the current account is "test1"
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
        "policyId": "$policies[0]",
        "expiry": "2016-09-05T22:53:37.000Z"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job

  Scenario: User renews their license
    Given I am an admin of account "test1"
    And the current account is "test1"
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
        "policyId": "$policies[0]",
        "expiry": "2016-12-01T22:53:37.000Z"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-12-31T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job

  Scenario: Admin renews a license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "duration": $time.1.month,
        "protected": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "2016-09-05T22:53:37.000Z"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job

  Scenario: Product renews a license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "duration": $time.1.month,
        "protected": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "2016-09-05T22:53:37.000Z"
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job

  Scenario: User renews their license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "duration": $time.1.month,
        "protected": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "2016-12-01T22:53:37.000Z"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to renew a license for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/renew"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin revokes a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job

  Scenario: User revokes their own license
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I am a user of account "test1"
    And the current user has 2 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job

  Scenario: Admin revokes a license that implements a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      {
        "protected": true
      }
      """
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job

  Scenario: Product revokes a license that implements a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      {
        "protected": true
      }
      """
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job

  Scenario: User revokes their own license that implements a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      {
        "protected": true
      }
      """
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I am a user of account "test1"
    And the current user has 2 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1/actions/revoke"
    Then the response status should be "403"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs

  Scenario: User tries to revoke another user's license
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0/actions/revoke"
    Then the response status should be "403"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin tries to revoke a license for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test2/licenses/$0/actions/revoke"
    Then the response status should be "401"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
