@api/v1
Feature: Show license

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
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Developer retrieves a license for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Sales retrieves a license for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Support retrieves a license for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Read-only retrieves a license for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a valid accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: application/json
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain the following raw headers:
      """
      Content-Type: application/json; charset=utf-8
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a deprioritized wildcard accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: application/json, text/plain, */*
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain the following raw headers:
      """
      Content-Type: application/json; charset=utf-8
      """
    And the response should contain a valid signature header for "test1"

  # FIXME(ezekg) is this a bug? feel like it should be application/vnd.api+json...
  Scenario: Admin retrieves a license for their account with a prioritized wildcard accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: */*, application/json, text/plain
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain the following raw headers:
      """
      Content-Type: application/json; charset=utf-8
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a wildcard accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: */*
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json; charset=utf-8
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a mixed accept header (JSONAPI)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: text/plain, application/vnd.api+json, application/json
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json; charset=utf-8
      """
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a mixed accept header (JSON)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: text/plain, application/json, application/html
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/json; charset=utf-8
      """
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with an unsupported accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: text/plain, text/html
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "400"

  Scenario: Admin retrieves a license for their account that has an owner
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """

  Scenario: Admin retrieves a license for their account that doesn't have an owner
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves a license for their account that has a user (v1.5)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I use an authentication token
    And I use API version "1.5"
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/user" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """

  Scenario: Admin retrieves a license for their account that doesn't have a user (v1.5)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": null }
      """
    And I use an authentication token
    And I use API version "1.5"
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/user" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves a license for their account by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "key": "a-license-key" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/a-license-key"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: Admin retrieves a license for their account that does not have a current version
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "lastValidatedVersion": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      { "version": null }
      """

  Scenario: Admin retrieves a license for their account that has a current version
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "lastValidatedVersion": "1.2.0" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      { "version": "1.2.0" }
      """

  Scenario: Admin retrieves a license for their account by UUID key that matches another account license by ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "id": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "id": "a9ad138d-a603-4309-85d0-764585bba99b",
        "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/977f1752-d6a9-4669-a6af-b039154ec40f"
    Then the response status should be "200"
    And the response body should be a "license" with the id "a9ad138d-a603-4309-85d0-764585bba99b"
    And the response body should be a "license" with the following attributes:
      """
      {
        "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """

  Scenario: Admin retrieves a license for their account by UUID that matches another account license by UUID key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "a9ad138d-a603-4309-85d0-764585bba99b",
        "id": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/977f1752-d6a9-4669-a6af-b039154ec40f"
    Then the response status should be "200"
    And the response body should be a "license" with the id "977f1752-d6a9-4669-a6af-b039154ec40f"
    And the response body should be a "license" with the following attributes:
      """
      {
        "key": "a9ad138d-a603-4309-85d0-764585bba99b"
      }
      """

  Scenario: Admin retrieves an invalid license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/invalid"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested license 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin retrieves a legacy encrypted license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 legacy encrypted "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" without a "key" attribute

  Scenario: Admin attempts to retrieve a legacy encrypted license for their account by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 legacy encrypted "licenses"
    And the first "license" has the following attributes:
      # Hashed 'a-license-key' using Bcrypt
      """
      { "key": "$2a$10$UcRHfYqf3DayM7iF/44pqOm0X9/UoEBcBRv3O4xFhJbXDIamHVBe." }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/a-license-key"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested license 'a-license-key' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_ENCRYPT
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_ENCRYPT"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_PSS_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_JWT_RS256
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_JWT_RS256"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_SIGN_V2
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN_V2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_PSS_SIGN_V2
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN_V2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme ED25519_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "ED25519_SIGN"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme ECDSA_P256_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "ECDSA_P256_SIGN"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieves an active license for their account (new license)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "createdAt": "$time.3.days.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "ACTIVE" }
      """

  Scenario: Admin attempts to retrieves an inactive license for their account (inactive license, unvalidated)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "lastValidatedAt": null,
        "createdAt": "$time.91.days.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "INACTIVE" }
      """

   Scenario: Admin attempts to retrieves an active license for their account (old license, recent validation)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.1.day.ago",
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "ACTIVE" }
      """

  Scenario: Admin attempts to retrieves an inactive license for their account (old license, old validation)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.91.days.ago",
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "INACTIVE" }
      """

  Scenario: Admin attempts to retrieves an old license for their account (old license, recent checkout)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "lastCheckOutAt": "$time.20.days.ago",
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "ACTIVE" }
      """

  Scenario: Admin attempts to retrieves an old license for their account (old license, old checkout)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "lastCheckOutAt": "$time.101.days.ago",
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "INACTIVE" }
      """

  Scenario: Admin attempts to retrieves an old license for their account (old license, recent checkin)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "lastCheckInAt": "$time.20.days.ago",
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "ACTIVE" }
      """

  Scenario: Admin attempts to retrieves an old license for their account (old license, old checkin)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "lastCheckInAt": "$time.101.days.ago",
        "createdAt": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "INACTIVE" }
      """

  Scenario: Admin attempts to retrieves an expired license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.91.days.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "EXPIRED" }
      """

  Scenario: Admin attempts to retrieves an expiring license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.days.from_now" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "EXPIRING" }
      """

  Scenario: Admin attempts to retrieves a suspended license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "status": "SUSPENDED" }
      """

  @ce
  Scenario: Environment retrieves a license (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves a license (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  @ee
  Scenario: Environment retrieves a license (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  @ee
  Scenario: Environment retrieves a license (global)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: Product retrieves a license for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: Product attempts to retrieve a license for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a license for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: License retrieves their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: License attempts to retrieve another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1"
    Then the response status should be "404"

  Scenario: Admin retrieves a license with a correct machine core counter cache
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 4 "machines" for the first "license" with the following:
      """
      { "cores": 8 }
      """
    And I use an authentication token
    And I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "machines": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/machines" },
          "meta": { "cores": 32, "memory": 0, "disk": 0, "count": 4 }
        }
      }
      """

  Scenario: Admin retrieves a license with a correct machine memory counter cache
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 4 "machines" for the first "license" with the following:
      """
      { "memory": 34359738368 }
      """
    And I use an authentication token
    And I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "machines": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/machines" },
          "meta": { "cores": 0, "memory": 137438953472, "disk": 0, "count": 4 }
        }
      }
      """

  Scenario: Admin retrieves a license with a correct machine disk counter cache
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 4 "machines" for the first "license" with the following:
      """
      { "disk": 1099511627776 }
      """
    And I use an authentication token
    And I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "machines": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/machines" },
          "meta": { "cores": 0, "memory": 0, "disk": 4398046511104, "count": 4 }
        }
      }
      """

  Scenario: Admin retrieves a license with a correct user counter cache
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "user"
    And the current account has 2 "licenses" for the last "user" as "owner"
    And the current account has 4 "license-users" for each "license"
    And I use an authentication token
    And I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following relationships:
      """
      {
        "users": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/users" },
          "meta": { "count": 5 }
        }
      }
      """

  # Scenario: Admin requests a license with an invalid URI
  #   Given I am an admin of account "test1"
  #   And the current account is "test1"
  #   And the current account has 1 "webhook-endpoint"
  #   And I use an authentication token
  #   When I send a GET request to "/accounts/test1/licenses/[invalid-url]"
  #   Then the response status should be "400"
  #   And the response body should be an array of 1 error
  #   And the first error should have the following properties:
  #     """
  #     {
  #       "title": "Bad request",
  #       "detail": "The request could not be completed because the URI was invalid (please ensure non-URL safe chars are properly encoded)",
  #       "code": "URI_INVALID"
  #     }
  #     """
  #   And sidekiq should have 0 "webhook" jobs
  #   And sidekiq should have 0 "metric" jobs
  #   And sidekiq should have 1 "request-log" job
