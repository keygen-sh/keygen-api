@api/v1
Feature: Machine checkout actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "403"

  Scenario: Anonymous performs a machine checkout
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a machine checkout
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product performs a machine checkout for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a machine checkout
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License performs a machine checkout for another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a machine checkout for their license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User performs a machine checkout for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin performs a machine checkout (default)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert signed with "ed25519"
    And the response should be a "MACHINE" cert with the following encoded data:
      """
      {
        "meta": {
          "iat": "2022-03-22T14:52:48.000Z",
          "exp": "2022-04-22T14:52:48.000Z",
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

  Scenario: Admin performs a machine checkout (encrypted)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout?encrypt=1"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert signed with "ed25519"
    And the response should be a "MACHINE" cert with the following encrypted data:
      """
      {
        "meta": {
          "iat": "2022-03-22T14:52:48.000Z",
          "exp": "2022-04-22T14:52:48.000Z",
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

  Scenario: Admin performs a machine checkout (Ed25519)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
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
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert signed with "ed25519"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout (RSA-PSS)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
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
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert signed with "rsa-pss-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout (RSA)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
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
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert signed with "rsa-sha256"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout (TTL)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout?ttl=3600"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert with the following encoded data:
      """
      {
        "meta": {
          "iat": "2022-03-22T14:52:48.000Z",
          "exp": "2022-03-22T15:52:48.000Z",
          "ttl": 3600
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout (no TTL)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout" with the following:
      """
      {
        "meta": {
          "ttl": null
        }
      }
      """
    Then the response status should be "200"
    And the response should be a "MACHINE" cert with the following encoded data:
      """
      {
        "meta": {
          "iat": "2022-03-22T14:52:48.000Z",
          "exp": null,
          "ttl": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout (included license)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout?include=license"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert with the following encoded data:
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
    And time is unfrozen

  Scenario: Admin performs a machine checkout (included product)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout?include=license.product"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert with the following encoded data:
      """
      {
        "included": [
          { "type": "products", "id": "$products[0]" },
          { "type": "licenses", "id": "$licenses[0]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Admin performs a machine checkout (included entitlements)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "policy-entitlement" for the last "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "license-entitlements" for the last "license"
    And the current account has 1 "machine" for the last "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout?include=license.entitlements"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert with the following encoded data:
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
    And time is unfrozen

  Scenario: Admin performs a machine checkout (included group)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the current account has 1 "machine"
    And the last "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout?include=group"
    Then the response status should be "200"
    And the response should be a "MACHINE" cert with the following encoded data:
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
    And time is unfrozen

  Scenario: Admin performs a machine checkout (encrypted includes)
    Given time is frozen at "2022-03-22T14:52:48.642Z"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/checkout?include=license.policy,license.user" with the following:
      """
      { "meta": { "encrypt": true } }
      """
    Then the response status should be "200"
    And the response should be a "MACHINE" cert with the following encrypted data:
      """
      {
        "included": [
          { "type": "policies", "id": "$policies[0]" },
          { "type": "licenses", "id": "$licenses[0]" },
          { "type": "users", "id": "$users[1]" }
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen
