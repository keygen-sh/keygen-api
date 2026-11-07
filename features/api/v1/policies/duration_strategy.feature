@api/v1
Feature: Policy duration strategy
  Background:
    Given the following "accounts" exist:
      | Name   | Slug  |
      | Test 1 | test1 |
    And I send and accept JSON
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And I use an authentication token

  Scenario: Policies keep calendar arithmetic when no strategy is supplied
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": { "name": "Calendar", "duration": 7776000 },
          "relationships": {
            "product": { "data": { "type": "products", "id": "$products[0]" } }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "policy" with the durationStrategy "CALENDAR"

  Scenario Outline: Admin explicitly selects a duration strategy on creation
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "90 days",
            "duration": 7776000,
            "durationStrategy": "<strategy>"
          },
          "relationships": {
            "product": { "data": { "type": "products", "id": "$products[0]" } }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "policy" with the durationStrategy "<strategy>"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the durationStrategy "<strategy>"

    Examples:
      | strategy |
      | CALENDAR |
      | SECONDS  |

  Scenario Outline: Admin changes an existing policy's duration strategy
    Given the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "durationStrategy": "<previous>" }
      """
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": { "durationStrategy": "<strategy>" }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "policy" with the durationStrategy "<strategy>"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the durationStrategy "<strategy>"

    Examples:
      | previous | strategy |
      | SECONDS  | CALENDAR |
      | CALENDAR | SECONDS  |

  Scenario Outline: License creation uses the policy's duration strategy
    Given time is frozen at "2026-10-09T00:00:00Z"
    And the current account has 1 "policy" with the following attributes:
      """
      { "duration": 7776000, "durationStrategy": "<strategy>" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": { "data": { "type": "policies", "id": "$policies[0]" } }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the expiry "<expiry>"

    Examples:
      | strategy | expiry                   |
      | CALENDAR | 2027-01-07T03:01:48.000Z |
      | SECONDS  | 2027-01-07T00:00:00.000Z |

  Scenario Outline: An unrelated update preserves the policy's duration strategy
    Given the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "durationStrategy": <strategy> }
      """
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": { "name": "Renamed" }
        }
      }
      """
    Then the response status should be "200"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "name": "Renamed", "durationStrategy": <strategy> }
      """

    Examples:
      | strategy   |
      | null       |
      | "CALENDAR" |
      | "SECONDS"  |

  Scenario Outline: Delayed first activation uses the policy's duration strategy
    Given time is frozen at "2026-10-09T00:00:00Z"
    And the current account has 1 "policy" with the following attributes:
      """
      {
        "duration": 7776000,
        "durationStrategy": <strategy>,
        "expirationBasis": "FROM_FIRST_ACTIVATION"
      }
      """
    And the first "policy" has the following attributes:
      """
      { "durationStrategy": <strategy> }
      """
    And the current account has 1 "license" for the first "policy"
    And time is frozen at "2027-01-31T00:00:00Z"
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": { "fingerprint": "delayed-activation" },
          "relationships": {
            "license": { "data": { "type": "licenses", "id": "$licenses[0]" } }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should process 1 "event-notification" job
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "<expiry>"

    Examples:
      | strategy   | expiry                   |
      | null       | 2027-04-29T03:01:48.000Z |
      | "CALENDAR" | 2027-04-29T03:01:48.000Z |
      | "SECONDS"  | 2027-05-01T00:00:00.000Z |

  Scenario Outline: Checkout endpoints sign certificates using the policy's duration strategy
    Given time is frozen at "2026-10-09T00:00:00Z"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "durationStrategy": <strategy> }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "machine" for the first "license"
    When I send a POST request to "/accounts/test1/<resources>/$0/actions/check-out" with the following:
      """
      { "meta": { "ttl": 7776000 } }
      """
    Then the response status should be "200"
    And the response body should be a "<resource>-file" with a certificate signed using "ed25519"
    And the response body should be a "<resource>-file" with the following attributes:
      """
      { "issued": "2026-10-09T00:00:00.000Z", "expiry": "<expiry>", "ttl": 7776000 }
      """
    And the response body should be a "<resource>-file" with the following encoded certificate data:
      """
      { "meta": { "issued": "2026-10-09T00:00:00.000Z", "expiry": "<expiry>", "ttl": 7776000 } }
      """
    When I send a GET request to "/accounts/test1/<resources>/$0/actions/check-out?ttl=7776000"
    Then the response status should be "200"
    And the response should be a "<certificate>" certificate signed using "ed25519"
    And the response should be a "<certificate>" certificate with the following encoded data:
      """
      { "meta": { "issued": "2026-10-09T00:00:00.000Z", "expiry": "<expiry>", "ttl": 7776000 } }
      """

    Examples:
      | resource | resources | certificate | strategy   | expiry                   |
      | license  | licenses  | LICENSE     | null       | 2027-01-07T03:01:48.000Z |
      | license  | licenses  | LICENSE     | "CALENDAR" | 2027-01-07T03:01:48.000Z |
      | license  | licenses  | LICENSE     | "SECONDS"  | 2027-01-07T00:00:00.000Z |
      | machine  | machines  | MACHINE     | null       | 2027-01-07T03:01:48.000Z |
      | machine  | machines  | MACHINE     | "CALENDAR" | 2027-01-07T03:01:48.000Z |
      | machine  | machines  | MACHINE     | "SECONDS"  | 2027-01-07T00:00:00.000Z |

  Scenario: Admin cannot select an unsupported duration strategy
    Given the current account has 1 "policy"
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": { "durationStrategy": "HOURS" }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "unsupported duration strategy",
        "source": { "pointer": "/data/attributes/durationStrategy" }
      }
      """
