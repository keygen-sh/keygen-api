@api/v1
Feature: Machine checkout actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled (POST)
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "403"

  Scenario: Endpoint should be inaccessible when account is disabled (GET)
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "403"

  Scenario: Anonymous performs a machine checkout (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous performs a machine checkout (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with defaults (POST)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json
      """
    And the JSON response should be a "machine-file" with a certificate signed using "ed25519"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-04-22T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "machines",
          "id": "$machines[0]"
        }
      }
      """
    And the JSON response should be a "machine-file" with the following attributes:
      """
      {
        "issued": "2022-03-22T14:52:48.000Z",
        "expiry": "2022-04-22T14:52:48.000Z",
        "ttl": 2629746
      }
      """
    And the JSON response should be a "machine-file" with the following relationships:
      """
      {
        "machine": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]" },
          "data": { "type": "machines", "id": "$machines[0]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout with defaults (GET)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "id": "dc664944-c4e3-49a5-a3f8-a8804ffd804d" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Disposition: attachment; filename="dc664944-c4e3-49a5-a3f8-a8804ffd804d.lic"
      Content-Type: application/octet-stream
      """
    And the response should be a "MACHINE" certificate signed using "ed25519"
    And the response should be a "MACHINE" certificate with the following encoded data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-04-22T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "machines",
          "id": "$machines[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs an encrypted machine checkout (POST)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
      """
      { "meta": { "encrypt": true } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with a certificate signed using "ed25519"
    And the JSON response should be a "machine-file" with the following encrypted certificate data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-04-22T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "machines",
          "id": "$machines[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs an encrypted machine checkout (GET)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?encrypt=1"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate signed using "ed25519"
    And the response should be a "MACHINE" certificate with the following encrypted data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-04-22T14:52:48.000Z",
          "ttl": 2629746
        },
        "data": {
          "type": "machines",
          "id": "$machines[0]"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout using Ed25519 (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "ED25519_SIGN" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with a certificate signed using "ed25519"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout using Ed25519 (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "ED25519_SIGN" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate signed using "ed25519"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout using RSA-PSS (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with a certificate signed using "rsa-pss-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout using RSA-PSS (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate signed using "rsa-pss-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout using RSA (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with a certificate signed using "rsa-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout using RSA (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_SIGN_V2" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate signed using "rsa-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with a custom TTL (POST)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
      """
      { "meta": { "ttl": 86400 } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-03-23T14:52:48.000Z",
          "ttl": 86400
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout with a custom TTL (GET)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?ttl=3600"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate with the following encoded data:
      """
      {
        "meta": {
          "issued": "2022-03-22T14:52:48.000Z",
          "expiry": "2022-03-22T15:52:48.000Z",
          "ttl": 3600
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout with a nil TTL (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
      """
      { "meta": { "ttl": null } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
      """
      { "meta": { "ttl": 2629746 } }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with an empty TTL (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?ttl="
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

  Scenario: Admin performs a machine checkout with an invalid TTL (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
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

  Scenario: Admin performs a machine checkout with an invalid TTL (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?ttl=1"
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

  Scenario: Admin performs a machine checkout with a license include (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out?include=license"
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with a license include (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?include=license"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with a policy include (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out?include=license.policy"
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" },
          { "type": "policies", "id": "$policies[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with a policy include (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?include=license.policy"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" },
          { "type": "policies", "id": "$policies[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout a product include (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["license.product"] } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" },
          { "type": "products", "id": "$products[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout a product include (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?include=license.product"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" },
          { "type": "products", "id": "$products[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with entitlement includes (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "license-entitlements" for the last "license"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["license.entitlements"] } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
      """
      {
        "included": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" },
          { "type": "licenses", "id": "$licenses[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with entitlement includes (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "license-entitlements" for the last "license"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?include=license.entitlements"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate with the following encoded data:
      """
      {
        "included": [
          { "type": "entitlements", "id": "$entitlements[0]" },
          { "type": "entitlements", "id": "$entitlements[1]" },
          { "type": "entitlements", "id": "$entitlements[2]" },
          { "type": "licenses", "id": "$licenses[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with a group include (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
      """
      { "meta": { "include": ["group"] } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encoded certificate data:
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

  Scenario: Admin performs a machine checkout with a group include (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?include=group"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate with the following encoded data:
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

  Scenario: Admin performs a machine checkout with encrypted includes (POST)
    Given time is frozen at "2022-03-22T14:52:48.000Z"
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
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out?include=license.policy,license.user" with the following:
      """
      { "meta": { "encrypt": true } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine-file" with the following encrypted certificate data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" },
          { "type": "policies", "id": "$policies[0]" },
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout with encrypted includes (GET)
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
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?include=license.policy,license.user&encrypt=true"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate with the following encrypted data:
      """
      {
        "included": [
          { "type": "licenses", "id": "$licenses[0]" },
          { "type": "policies", "id": "$policies[0]" },
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout with invalid includes (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out" with the following:
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

  Scenario: Admin performs a machine checkout with invalid includes (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out?include=account"
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

  Scenario: Admin performs a machine checkout by fingerprint (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "fingerprint": "41:34:7C:7E:B2:AD:65:96:5A" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/41:34:7C:7E:B2:AD:65:96:5A/actions/check-out"
    Then the response status should be "200"
    And the JSON response should be a "machine-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout by fingerprint (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "fingerprint": "41:34:7C:7E:B2:AD:65:96:5A" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/41:34:7C:7E:B2:AD:65:96:5A/actions/check-out"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a machine checkout (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the JSON response should be a "machine-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a machine checkout (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a checkout for a machine of another product (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a checkout for a machine of another product (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a machine checkout (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the JSON response should be a "machine-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a machine checkout (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a machine checkout for another machine (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 2 "machines"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$1/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a machine checkout for another machine (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 2 "machines"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$1/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a machine checkout for their machine (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the JSON response should be a "machine-file"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a machine checkout for their machine (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "200"
    And the response should be a "MACHINE" certificate
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a machine checkout for a machine they don't own (POST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a machine checkout for a machine they don't own (GET)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/actions/check-out"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
