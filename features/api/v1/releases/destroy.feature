@api/v1
Feature: Delete release

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
    And the current account has 1 "release"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their releases
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "204"
    And the current account should have 2 "releases"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes one of their releases
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "204"
    And the current account should have 2 "releases"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales deletes one of their releases
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "403"

  Scenario: Support deletes one of their releases
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "403"

  Scenario: Product deletes one of their releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases" for the first "product"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "204"
    And the current account should have 2 "releases"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete a release for their product
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "403"

  Scenario: User attempts to delete a release for their product
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "403"

  Scenario: Anonymous attempts to delete a release
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    When I send a DELETE request to "/accounts/test1/releases/$2"
    Then the response status should be "401"

  Scenario: Admin attempts to delete a release for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "releases"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
