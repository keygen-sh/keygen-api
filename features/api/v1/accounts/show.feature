@api/v1
Feature: Show account
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1"
    Then the response status should not be "403"

  Scenario: Admin retrieves their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "account"
    And the response body should be an "account" with the following meta:
      """
      {
        "publicKey": "$~accounts[0].public_key",
        "keys": {
          "ed25519": "$~accounts[0].ed25519_public_key",
          "rsa2048": "$~accounts[0].public_key"
        }
      }
      """
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Isolated admin retrieves their account
    Given the current account is "test1"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1?environment=isolated"
    Then the response status should be "200"

  @ee
  Scenario: Shared admin retrieves their account
    Given the current account is "test1"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1?environment=shared"
    Then the response status should be "200"

  Scenario: Developer retrieves their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"

  Scenario: Sales retrieves their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"

  Scenario: Support retrieves their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"

  Scenario: Read-only user retrieves their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"

  @ce
  Scenario: Environment retrieves their account (isolated)
    Given the account "test1" is subscribed
    And the account "test1" has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment retrieves their account (isolated)
    Given the account "test1" is subscribed
    And the account "test1" has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment retrieves their account (shared)
    Given the account "test1" is subscribed
    And the account "test1" has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment retrieves their account (global)
    Given the account "test1" is subscribed
    And the account "test1" has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "401"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product retrieves their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: License attempts to retrieve an account (default permission)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "403"

  Scenario: License attempts to retrieve an account (has permission)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the last "license" has the following permissions:
      """
      ["account.read"]
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"

  Scenario: License attempts to retrieve an account (no permission)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the last "license" has the following permissions:
      """
      []
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "403"

  Scenario: User attempts to retrieve an account (default permission)
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "403"

  Scenario: User attempts to retrieve an account (has permission)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the last "user" has the following permissions:
      """
      ["account.read"]
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"

  Scenario: User attempts to retrieve an account (no permission)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the last "user" has the following permissions:
      """
      []
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "403"

  Scenario: User attempts to retrieve an invalid account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested account 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin retrieves their account, accepting no content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": null }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting any content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "*/*" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting any content-type with metadata
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      # This is the accept header Stripe sends us
      """
      { "Accept": "*/*; q=0.5, application/xml" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting JSONAPI content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/vnd.api+json" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting JSON content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/json" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/json" }
      """

  Scenario: Admin retrieves their account, accepting XML content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/xml" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"

  Scenario: Admin retrieves their account, accepting HTML content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "text/html" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"

  Scenario: Admin retrieves their account, accepting plain-text content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "text/plain" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"

  Scenario: Admin retrieves their account, accepting an ed25519 signature algorithm
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Accept-Signature": "algorithm=\"ed25519\"" }
      """
    When I send a GET request to "/accounts/test1"
    And the response should contain a valid "ed25519" signature header for "test1"
    Then the response status should be "200"

  Scenario: Admin retrieves their account, accepting an rsa-pss-sha256 signature algorithm
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Accept-Signature": "algorithm=\"rsa-pss-sha256\"" }
      """
    When I send a GET request to "/accounts/test1"
    And the response should contain a valid "rsa-pss-sha256" signature header for "test1"
    Then the response status should be "200"

  Scenario: Admin retrieves their account, accepting an rsa-sha256 signature algorithm
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Accept-Signature": "algorithm=\"rsa-sha256\"" }
      """
    When I send a GET request to "/accounts/test1"
    And the response should contain a valid "rsa-sha256" signature header for "test1"
    Then the response status should be "200"

  Scenario: Admin retrieves their account, accepting an invalid signature algorithm
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Accept-Signature": "algorithm=\"rsa-sha1\"" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"

  Scenario: Admin retrieves their account, accepting an invalid signature keyid
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Accept-Signature": "keyid=\"1\" algorithm=\"ed25519\"" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"

  Scenario: Admin retrieves their account, accepting a valid signature keyid
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Accept-Signature": "keyid=\"$accounts[0].id\", algorithm=\"ed25519\"" }
      """
    When I send a GET request to "/accounts/test1"
    And the response should contain a valid "ed25519" signature header for "test1"
    Then the response status should be "200"

  Scenario: Admin retrieves their account with a malformed accept signature header
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Accept-Signature": "<algorithm:rsa>" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"
