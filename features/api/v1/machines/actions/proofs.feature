@api/v1
Feature: Machine proof actions

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
    When I send a POST request to "/accounts/test1/machines/$0/actions/generate-offline-proof"
    Then the response status should be "403"

  Scenario: Admin generates a proof for a machine with the default dataset
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/generate-offline-proof"
    Then the response status should be "200"
    And the JSON response should be a "machine"
    And the JSON response should be meta that contains a valid activation proof of the following dataset:
      """
      {
        "account": {
          "id": "$machines[0].account.id"
        },
        "product": {
          "id": "$machines[0].product.id"
        },
        "policy": {
          "id": "$machines[0].policy.id",
          "duration": $machines[0].policy.duration
        },
        "license": {
          "id": "$machines[0].license.id",
          "key": "$machines[0].license.key",
          "expiry": "$machines[0].license.expiry"
        },
        "machine": {
          "id": "$machines[0].id",
          "fingerprint": "$machines[0].fingerprint",
          "created": "$machines[0].created_at"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin generates a proof for a machine with a custom dataset
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/generate-offline-proof" with the following:
      """
      {
        "meta": {
          "dataset": {
            "fingerprint": "$machines[0].fingerprint",
            "id": "$machines[0].id",
            "nonce": 1
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine"
    And the JSON response should be meta that contains a valid activation proof of the following dataset:
      """
      {
        "fingerprint": "$machines[0].fingerprint",
        "id": "$machines[0].id",
        "nonce": 1
      }
      """
    And the response should contain a valid signature header for "test1"

  Scenario: License attempts to generate a proof for a machine with a custom dataset
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/generate-offline-proof" with the following:
      """
      {
        "meta": {
          "dataset": {
            "fingerprint": "$machines[0].fingerprint",
            "license": "$licenses[0].id",
            "timer": 2592000
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: meta"
      }
      """

  Scenario: License generates a proof for their machine
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/generate-offline-proof"
    Then the response status should be "200"
    And the JSON response should be a "machine"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be meta that contains a valid activation proof of the following dataset:
      """
      {
        "account": {
          "id": "$machines[0].account.id"
        },
        "product": {
          "id": "$machines[0].product.id"
        },
        "policy": {
          "id": "$machines[0].policy.id",
          "duration": $machines[0].policy.duration
        },
        "license": {
          "id": "$machines[0].license.id",
          "key": "$machines[0].license.key",
          "expiry": "$machines[0].license.expiry"
        },
        "machine": {
          "id": "$machines[0].id",
          "fingerprint": "$machines[0].fingerprint",
          "created": "$machines[0].created_at"
        }
      }
      """

  Scenario: License attempts to generate a proof for a machine that isn't theirs
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines/$0/actions/generate-offline-proof" with the following:
      """
      {
        "meta": {
          "dataset": {
            "fingerprint": "$machines[0].fingerprint",
            "license": "$licenses[0].id",
            "timer": 2592000
          }
        }
      }
      """
    Then the response status should be "404"
