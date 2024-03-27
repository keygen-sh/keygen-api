@api/v1
Feature: Delete license

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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$2"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes one of their licenses
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$2"
    Then the response status should be "204"
    And the current account should have 2 "licenses"

  Scenario: Sales deletes one of their licenses
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$2"
    Then the response status should be "204"
    And the current account should have 2 "licenses"

  Scenario: Support deletes one of their licenses
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$2"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"
    And the current account should have 3 "licenses"

  Scenario: Read-only deletes one of their licenses
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$2"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "403"
    And the current account should have 3 "licenses"

  @ee
  Scenario: Environment attempts to delete an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "licenses"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "204"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a shared license
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "licenses"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "204"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a global license
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 2 global "licenses"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"
    And the current account should have 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete their license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "licenses" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "204"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete another product's license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 2 "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "404"
    And the current account should have 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the current account should have 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete one of their licenses (license owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["license.deleted"]
      }
      """
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1"
    Then the response status should be "204"
    And the current account should have 2 "licenses"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete one of their licenses (license user)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["license.deleted"]
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"
    And the current account should have 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete a license for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete a license for their group
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous user attempts to delete a license for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    When I send a DELETE request to "/accounts/test1/licenses/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete a license for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/licenses/$1"
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And the response body should be an array of 1 error
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
