@api/v1
Feature: License validation actions

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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"

  Scenario: Anonymous validates a check-in license that is valid
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "lastCheckInAt": "$time.now"
      }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin validates a check-in license that is valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "lastCheckInAt": "$time.now"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a check-in license that is overdue
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "lastCheckInAt": "$time.1.day.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": false, "detail": "is overdue for check in" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a strict license that is valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a suspended license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
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
        "expiry": "$time.1.day.from_now",
        "suspended": true
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": false, "detail": "is suspended" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a strict floating license that has too many machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 5,
        "floating": true,
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": false, "detail": "has too many associated machines" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a strict license that has too many machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "floating": false,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": false, "detail": "has too many associated machines" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a non-strict license that has too many machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a license that has not been used
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a strict floating license that has not been used
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "floating": true,
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": false, "detail": "must have at least 1 associated machine" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a strict license that has not been used
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "floating": false,
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": false, "detail": "must have exactly 1 associated machine" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a license that is expired
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 3 "licenses"
    And the current account has 1 "webhook-endpoint"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": false, "detail": "is expired" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a valid license by key
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the current account has 1 "webhook-endpoint"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
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
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates an invalid license by key
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the current account has 1 "webhook-endpoint"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.ago"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
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
      { "valid": false, "detail": "does not exist" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates an encrypted license by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 encrypted "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
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
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates an encrypted license key as an unencrypted key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 encrypted "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
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
      { "valid": false, "detail": "does not exist" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates an unencrypted license key as an encrypted key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
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
      { "valid": false, "detail": "does not exist" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates a valid license by key from a pool
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
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
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
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
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a valid license that used a pre-determined key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "a"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "a"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be meta with the following:
      """
      { "valid": true, "detail": "is valid" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a blank license key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "a"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": ""
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs