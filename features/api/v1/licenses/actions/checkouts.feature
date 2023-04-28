@api/v1
Feature: License checkout actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled (POST)
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "403"

  Scenario: Endpoint should be inaccessible when account is disabled (GET)
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "403"

  Scenario: Anonymous performs a license checkout (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous performs a license checkout (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with defaults (POST)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json
      """
    And the response body should be a "license-file" with a certificate signed using "ed25519"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "meta": {
          "issued": "2022-10-16T14:52:48.000Z",
          "expiry": "2022-11-16T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "licenses",
          "id": "$licenses[0]"
        }
      }
      """
    And the response body should be a "license-file" with the following attributes:
      """
      {
        "issued": "2022-10-16T14:52:48.000Z",
        "expiry": "2022-11-16T14:52:48.000Z",
        "ttl": 2629746
      }
      """
    And the response body should be a "license-file" with the following relationships:
      """
      {
        "license": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]" },
          "data": { "type": "licenses", "id": "$licenses[0]" }
        }
      }
      """
    And the last "license" should have the following attributes:
      """
      { "lastCheckOutAt": "2022-10-16T14:52:48.000Z" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a license checkout with defaults (GET)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "id": "dc664944-c4e3-49a5-a3f8-a8804ffd804d" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Disposition: attachment; filename="dc664944-c4e3-49a5-a3f8-a8804ffd804d.lic"
      Content-Type: application/octet-stream
      """
    And the response should be a "LICENSE" certificate signed using "ed25519"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "meta": {
          "issued": "2022-10-16T14:52:48.000Z",
          "expiry": "2022-11-16T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "licenses",
          "id": "$licenses[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs an encrypted license checkout (POST)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "encrypt": true } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with a certificate signed using "ed25519"
    And the response body should be a "license-file" with the following encrypted certificate data:
      """
      {
        "meta": {
          "issued": "2022-10-16T14:52:48.000Z",
          "expiry": "2022-11-16T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "licenses",
          "id": "$licenses[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs an encrypted license checkout (GET)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?encrypt=1"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate signed using "ed25519"
    And the response should be a "LICENSE" certificate with the following encrypted data:
      """
      {
        "meta": {
          "issued": "2022-10-16T14:52:48.000Z",
          "expiry": "2022-11-16T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "licenses",
          "id": "$licenses[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs an encrypted license checkout with blank value (POST)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "encrypt": null } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with a certificate signed using "ed25519"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-04-22T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "licenses",
          "id": "$licenses[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs an encrypted license checkout with blank value (GET)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?encrypt="
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate signed using "ed25519"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-04-22T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "licenses",
          "id": "$licenses[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a license checkout using Ed25519 (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "ED25519_SIGN" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file" with a certificate signed using "ed25519"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout using Ed25519 (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "ED25519_SIGN" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate signed using "ed25519"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout using RSA-PSS (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file" with a certificate signed using "rsa-pss-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout using RSA-PSS (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate signed using "rsa-pss-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout using RSA (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file" with a certificate signed using "rsa-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout using RSA (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate signed using "rsa-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a custom TTL (POST)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "ttl": 86400 } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "meta": {
          "issued": "2022-10-16T14:52:48.000Z",
          "expiry": "2022-10-17T14:52:48.000Z",
          "ttl": 86400
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a license checkout with a custom TTL (GET)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?ttl=3600"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "meta": {
          "issued": "2022-10-16T14:52:48.000Z",
          "expiry": "2022-10-16T15:52:48.000Z",
          "ttl": 3600
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a license checkout with a nil TTL (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "ttl": null } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "meta": {
          "expiry": null,
          "ttl": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with an empty TTL (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?ttl="
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "meta": {
          "expiry": null,
          "ttl": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a TTL that is too short (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "ttl": 60 } }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be greater than or equal to 3600 (1 hour)",
        "code": "CHECKOUT_TTL_INVALID",
        "source": {
          "parameter": "ttl"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a TTL that is too short (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?ttl=1"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be greater than or equal to 3600 (1 hour)",
        "code": "CHECKOUT_TTL_INVALID",
        "source": {
          "parameter": "ttl"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a TTL that is too long (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "ttl": 31556953 } }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be less than or equal to 31556952 (1 year)",
        "code": "CHECKOUT_TTL_INVALID",
        "source": {
          "parameter": "ttl"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a TTL that is too long (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?ttl=94670856"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be less than or equal to 31556952 (1 year)",
        "code": "CHECKOUT_TTL_INVALID",
        "source": {
          "parameter": "ttl"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a policy include (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=policy"
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "policies", "id": "$policies[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a policy include (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=policy"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "policies", "id": "$policies[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout a product include (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["product"] } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "products", "id": "$products[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout a product include (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=product"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "products", "id": "$products[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with entitlement includes (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "license-entitlements" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["entitlements"] } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with entitlement includes (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "license-entitlements" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=entitlements"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a group include (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["group"] } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "groups", "id": "$groups[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with a group include (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=group"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "groups", "id": "$groups[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin performs an isolated license checkout with environment includes (POST)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["environment"] } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "environments", "id": "$environments[0]" }
        ]
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin performs a shared license checkout with environment includes (GET)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=environment"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "environments", "id": "$environments[0]" }
        ]
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin performs a license checkout with environment includes (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["environment"] } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "environment": {
              "links": { "related": null },
              "data": null
            }
          }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin performs a license checkout with environment includes (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=environment"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "environment": {
              "links": { "related": null },
              "data": null
            }
          }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with encrypted includes (POST)
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=policy,user" with the following:
      """
      { "meta": { "encrypt": true } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encrypted certificate data:
      """
      {
        "included": [
          { "type": "policies", "id": "$policies[0]" },
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a license checkout with encrypted includes (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=policy,user&encrypt=true"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encrypted data:
      """
      {
        "included": [
          { "type": "policies", "id": "$policies[0]" },
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with invalid includes (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["account"] } }
      """
    Then the response status should be "400"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json
      """
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "invalid includes",
        "code": "CHECKOUT_INCLUDE_INVALID",
        "source": {
          "parameter": "include"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with invalid includes (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=account"
    Then the response status should be "400"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json
      """
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "invalid includes",
        "code": "CHECKOUT_INCLUDE_INVALID",
        "source": {
          "parameter": "include"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with empty includes (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": [] } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      { "included": [] }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout with empty includes (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include="
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      { "included": [] }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

   Scenario: Admin performs a license checkout by key (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "key": "0092E3-41347C-7EB2AD-65965A-0C3224-V3" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/0092E3-41347C-7EB2AD-65965A-0C3224-V3/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a license checkout by key (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "key": "0092E3-41347C-7EB2AD-65965A-0C3224-V3" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/0092E3-41347C-7EB2AD-65965A-0C3224-V3/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment performs an isolated license checkout (GET)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "environment": {
              "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment performs an isolated license checkout (POST)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "environment": {
              "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment performs a shared license checkout with environment includes (GET)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=environment"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate with the following encoded data:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "environment": {
              "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        },
        "included": [
          { "type": "environments", "id": "$environments[0]" }
        ]
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment performs a shared license checkout with environment includes (POST)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["environment"] } }
      """
    Then the response status should be "200"
    And the response body should be a "license-file" with the following encoded certificate data:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "environment": {
              "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        },
        "included": [
          { "type": "environments", "id": "$environments[0]" }
        ]
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment performs a global license checkout with environment includes (POST)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["environment"] } }
      """
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a license checkout (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a license checkout (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a checkout for a license of another product (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a checkout for a license of another product (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout for another license (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout without checkout permission (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" with the following:
      """
      { "permissions": ["license.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=product"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout without checkout permission (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" with the following:
      """
      { "permissions": ["license.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=policy"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout without include permission (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" with the following:
      """
      { "permissions": ["license.check-out", "license.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=product"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout without include permission (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" with the following:
      """
      { "permissions": ["license.check-out", "license.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=policy"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout without include permission (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=environment"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout with permission (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" with the following:
      """
      { "permissions": ["license.check-out", "license.read", "product.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out?include=product"
    Then the response status should be "200"
    And the response body should be a "license-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout with permission (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" with the following:
      """
      { "permissions": ["license.check-out", "license.read", "policy.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out?include=policy"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a license checkout for another license (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a license checkout for their license (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response body should be a "license-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a license checkout for their license (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "LICENSE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a license checkout for a license they don't own (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a license checkout for a license they don't own (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
