@api/v1
Feature: License permits

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin renews a license
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "duration": $time.1.month
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": $policies[0].id,
        "expiry": "2016-09-05T22:53:37.000Z"
      }
      """
    And I use my auth token
    When I send a POST request to "/licenses/$0/actions/renew"
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-10-05T22:53:37.000Z"

  Scenario: Admin revokes a license
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I use my auth token
    When I send a POST request to "/licenses/$0/actions/revoke"
    Then the response status should be "204"
    And the current account should have 2 "licenses"

  Scenario: User tries to revoke another user's license
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/licenses/$0/actions/revoke"
    Then the response status should be "403"
    And the current account should have 3 "licenses"

  Scenario: Admin tries to revoke a license for another account
    Given I am an admin of account "test1"
    And I am on the subdomain "test2"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And I use my auth token
    When I send a POST request to "/licenses/$0/actions/revoke"
    Then the response status should be "401"
    And the current account should have 3 "licenses"

  Scenario: Admin verifies a license that is valid
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": $policies[0].id,
        "expiry": "$time.1.day.from_now"
      }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": $licenses[0].id
      }
      """
    And I use my auth token
    When I send a GET request to "/licenses/$0/actions/verify"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": true }
      """

  Scenario: Admin verifies a license that has not been used
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": $policies[0].id,
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use my auth token
    When I send a GET request to "/licenses/$0/actions/verify"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """

  Scenario: Admin verifies a license that is expired
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": $policies[0].id,
        "expiry": "$time.1.day.ago"
      }
      """
    And I use my auth token
    When I send a GET request to "/licenses/$0/actions/verify"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """
