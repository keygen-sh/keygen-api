@api/v1
Feature: Account subscription actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin pauses their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/pause-subscription"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "paused"
      }
      """
    And sidekiq should have 1 "webhook" job

  Scenario: Admin resumes their paused account
    Given the account "test1" is paused
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/resume-subscription"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "resumed"
      }
      """
    And sidekiq should have 1 "webhook" job

  Scenario: Admin cancels their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/cancel-subscription"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "canceled"
      }
      """
    And sidekiq should have 1 "webhook" job

  Scenario: Admin renews their canceled account
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/renew-subscription"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      {
        "status": "renewed"
      }
      """
    And sidekiq should have 1 "webhook" job

  Scenario: Admin attempts to pause their paused account
    Given the account "test1" is paused
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/pause-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to resume their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/resume-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to cancel their canceled account
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/cancel-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to renews their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/renew-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to pause another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/pause-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to resume another account
    Given the account "test1" is paused
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/resume-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to cancel another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/cancel-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to renew another account
    Given the account "test1" is canceled
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/renew-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
