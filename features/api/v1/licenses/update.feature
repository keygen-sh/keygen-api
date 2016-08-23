@api/v1
Feature: Update license

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin updates a license expiry
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "expiry": "2016-09-05T22:53:37.000Z" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-09-05T22:53:37.000Z"

  Scenario: Admin updates a license policy
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "policy": "$policies[1]" } }
      """
    Then the response status should be "400"

  Scenario: Admin updates a license key
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "key": "a" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the key "a"
