@api/v1
Feature: License validation

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin validates a strict license that is valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 1,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": true }
      """

  Scenario: Admin validates a strict license that has too many machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 5,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And the current account has 6 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """

  Scenario: Admin validates a non-strict license that has too many machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 1,
        "strict": false
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": true }
      """

  Scenario: Admin validates a license that has not been used
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "strict": false
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": true }
      """

  Scenario: Admin validates a strict license that has not been used
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "strict": true
      }
      """
    And the current account has 2 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """

  Scenario: Admin validates a license that is expired
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """

  Scenario: Admin validates a valid license by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": true }
      """

  Scenario: Admin validates an invalid license by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.ago"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/validate-key" with the following:
      """
      {
        "meta": {
          "key": "invalid"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """

  Scenario: Admin validates an encrypted license by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 encrypted "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$crypt[0].raw",
          "encrypted": true
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": true }
      """

  Scenario: Admin validates an encrypted license key as an unencrypted key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 encrypted "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$crypt[0].raw",
          "encrypted": false
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """

  Scenario: Admin validates an unencrypted license key as an encrypted key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "encrypted": true
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": false }
      """

  Scenario: Admin validates a valid license by key from a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "usePool": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "isValid": true }
      """
