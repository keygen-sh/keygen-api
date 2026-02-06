@api/v1
Feature: Delete machine

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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "licenses"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the first "license" should have a correct machine core count
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes one of their machines
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "204"
    And the current account should have 2 "machines"

  Scenario: Sales deletes one of their machines
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "204"
    And the current account should have 2 "machines"

  Scenario: Support deletes one of their machines
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "403"
    And the current account should have 3 "machines"

  Scenario: Read-only deletes one of their machines
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "403"
    And the current account should have 3 "machines"

  @ee
  Scenario: Environment attempts to delete an isolated machine
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "machines"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 1 "machine"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a shared machine
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "machines"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 1 "machine"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a global machine
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 2 global "machines"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 2 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes a machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "204"
    And the current account should have 2 "machines"

  Scenario: Product deletes a machine for a different product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$2"
    Then the response status should be "404"
    And the current account should have 3 "machines"

  Scenario: Admin deletes one of their machines by fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "foo-bar-baz" }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/foo-bar-baz"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their machines by UUID fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "a06b4343-d2cf-45e7-b9a2-b11c618993f3" }
      """
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/a06b4343-d2cf-45e7-b9a2-b11c618993f3"
    Then the response status should be "204"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "machines"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to delete a machine that belongs to another user
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Owner deletes a machine for their unprotected license (is machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 0 "machines"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Owner deletes a machine for their unprotected license (not machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 0 "machines"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User deletes a machine for their unprotected license (is machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 0 "machines"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User deletes a machine for their unprotected license (not machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" with the following:
      """
      { "protected": false }
      """
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Owner deletes a machine for their protected license (is machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy" with the following:
      """
      { "protected": true }
      """
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Owner deletes a machine for their protected license (not machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "policy" with the following:
      """
      { "protected": true }
      """
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User deletes a machine for their protected license (is machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" with the following:
      """
      { "protected": true }
      """
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User deletes a machine for their protected license (not machine owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" with the following:
      """
      { "protected": true }
      """
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User deletes a machine for their group
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "groupId": "$groups[0]"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "404"
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License deletes a machine for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines" for the last "license"
    And the current account has 1 "webhook-endpoint"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 2 "machines"
    And the current token should have the following attributes:
      """
      { "deactivations": 1 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

    # Sanity check on license's machine counter
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "machines": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/machines" },
          "meta": {
            "cores": 0,
            "memory": 0,
            "disk": 0,
            "count": 2
          }
        }
      }
      """

  # Permissions
  Scenario: License deactivates a machine without permission
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 1 "webhook-endpoint"
    And I am a license of account "test1"
    And I authenticate with my license key
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "403"
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License deactivates a machine with permission
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["license.validate", "machine.delete"] }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 1 "webhook-endpoint"
    And I am a license of account "test1"
    And I authenticate with my license key
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "204"
    And the current account should have 2 "machines"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: License deletes a machine for their license but they've hit their deactivation limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the current account has 1 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      {
        "maxDeactivations": 1,
        "deactivations": 1
      }
      """
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "422"
    And the current account should have 1 "machine"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "exceeds maximum allowed (1)",
        "code": "DEACTIVATIONS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/deactivations"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License deletes a machine that belongs to another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the current account has 1 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$0"
    Then the response status should be "404"
    And the current account should have 1 "machine"
    And the current token should have the following attributes:
      """
      {
        "deactivations": 0
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous user attempts to delete a machine for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete a machine for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/machines/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
