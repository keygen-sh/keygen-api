@api/v1
Feature: License validation actions

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  # Quick validation
  Scenario: Quick validation endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"

  Scenario: Anonymous quick validates a check-in license that is valid
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

  Scenario: Admin quick validates a check-in license that is valid
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a check-in license that is overdue
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "is overdue for check in", "constant": "OVERDUE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a strict license that is valid
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a suspended license
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "is suspended", "constant": "SUSPENDED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a strict floating license that has too many machines
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has too many associated machines", "constant": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a strict license that has too many machines
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has too many associated machines", "constant": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a non-strict license that has too many machines
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a license that has not been used
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a strict floating license that has not been used
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "must have at least 1 associated machine", "constant": "NO_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a strict license that has not been used
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "must have exactly 1 associated machine", "constant": "NO_MACHINE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin quick validates a license by key that is expired
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 3 "licenses"
    And the current account has 1 "webhook-endpoint"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.ago",
        "key": "foobar"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/foobar/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "is expired", "constant": "EXPIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a floating license scoped to a mismatched machine fingerprint, but the license has no machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "floating": true
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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a node-locked license scoped to a mismatched machine fingerprint, but the license has no machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "floating": false
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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin quick validates a valid license that requires a product scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireProductScope": true
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin quick validates a valid license that requires a policy scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requirePolicyScope": true
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin quick validates a valid license that requires a machine scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireMachineScope": true
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin quick validates a valid license that requires a fingerprint scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireFingerprintScope": true
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  # License validation
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "is overdue for check in", "constant": "OVERDUE" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "is suspended", "constant": "SUSPENDED" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has too many associated machines", "constant": "TOO_MANY_MACHINES" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has too many associated machines", "constant": "TOO_MANY_MACHINES" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "must have at least 1 associated machine", "constant": "NO_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin validates a strict license by key that has not been used
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
        "expiry": "$time.1.day.from_now",
        "key": "a-b-c-d-e"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/a-b-c-d-e/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "must have exactly 1 associated machine", "constant": "NO_MACHINE" }
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "is expired", "constant": "EXPIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a valid license scoped to a specific product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "product": "$products[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a license scoped to a mismatched product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "product": "$products[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "product scope does not match", "constant": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a valid license scoped to a specific machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a license scoped to a mismatched machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "machine": "$machines[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "machine scope does not match", "constant": "MACHINE_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a valid license scoped to a specific machine fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a license scoped to a mismatched machine fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "fingerprint": "$machines[1].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "fingerprint scope does not match", "constant": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a floating license scoped to a mismatched machine fingerprint, but the license has no machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "floating": true
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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has no associated machines", "constant": "NO_MACHINES" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a node-locked license scoped to a mismatched machine fingerprint, but the license has no machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "floating": false
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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has no associated machine", "constant": "NO_MACHINE" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a valid license scoped to a specific policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "policy": "$policies[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates an license scoped to a mismatched policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "policy": "$policies[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "policy scope does not match", "constant": "POLICY_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a valid license scoped to a specific product and machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "product": "$products[0]",
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates an invalid license scoped to a specific product and machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "product": "$products[1]",
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "product scope does not match", "constant": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: An admin validates a valid license without a request body
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a valid license that requires a product scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireProductScope": true
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "product scope is required", "constant": "PRODUCT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a valid license that requires a policy scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requirePolicyScope": true
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "policy scope is required", "constant": "POLICY_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a valid license that requires a machine scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireMachineScope": true
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "machine scope is required", "constant": "MACHINE_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a valid license that requires a fingerprint scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireFingerprintScope": true
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
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "fingerprint scope is required", "constant": "FINGERPRINT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates a legacy encrypted license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "LEGACY",
        "encrypted": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates an encrypted license using RSA_2048_PKCS1_ENCRYPT
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "RSA_2048_PKCS1_ENCRYPT",
        "encrypted": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "key": "some-encrypted-payload"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: An admin validates an encrypted license using RSA_2048_PKCS1_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "RSA_2048_PKCS1_SIGN",
        "encrypted": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "key": "some-signed-payload"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  # Key validation
  Scenario: Key validation endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key"
    Then the response status should be "403"

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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
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
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates a legacy encrypted license by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 legacy encrypted "license"
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a legacy encrypted license key as an unencrypted key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 legacy encrypted "license"
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
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates an unencrypted license key as a legacy encrypted key
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
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates an encrypted license using RSA_2048_PKCS1_ENCRYPT by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 encrypted "license" using "RSA_2048_PKCS1_ENCRYPT"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "encrypted": false
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates an encrypted license using RSA_2048_PKCS1_ENCRYPT by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 encrypted "license" using "RSA_2048_PKCS1_ENCRYPT"
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
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates an encrypted license using RSA_2048_PKCS1_SIGN by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 encrypted "license" using "RSA_2048_PKCS1_SIGN"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "encrypted": false
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates an encrypted license using RSA_2048_PKCS1_SIGN by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 encrypted "license" using "RSA_2048_PKCS1_SIGN"
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
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
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
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
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

  Scenario: Anonymous validates a valid license key scoped to a specific product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "product": "$products[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a license key scoped to a mismatched product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "product": "$products[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "product scope does not match", "constant": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Anonymous validates an non-existent license key scoped to a specific product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "non-existent-key",
          "scope": {
            "product": "$products[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates a valid license key scoped to a specific machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a license key scoped to a mismatched machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "machine": "$machines[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "machine scope does not match", "constant": "MACHINE_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Anonymous validates a node-locked license key scoped to a machine, but the license has no machines
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "floating": false
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has no associated machine", "constant": "NO_MACHINE" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Anonymous validates a floating license key scoped to a machine, but the license has no machines
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "floating": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "has no associated machines", "constant": "NO_MACHINES" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Anonymous validates a valid license key scoped to a specific machine fingerprint
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a license key scoped to a mismatched machine fingerprint
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprint": "$machines[1].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "fingerprint scope does not match", "constant": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Anonymous validates an non-existent license key scoped to a machine fingerprint
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "non-existent-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates a valid license key scoped to a specific policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "policy": "$policies[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates an license key scoped to a mismatched policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "policy": "$policies[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "policy scope does not match", "constant": "POLICY_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Anonymous validates a non-existent license key scoped to a policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "non-existent-key",
          "scope": {
            "policy": "$policies[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should not contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "does not exist", "constant": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous validates a valid license key scoped to a specific product and machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "product": "$products[0]",
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates an invalid license key scoped to a specific product and machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "product": "$products[1]",
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "product scope does not match", "constant": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Anonymous validates a valid license key with an empty scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {}
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a valid license key that requires a product scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireProductScope": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "product scope is required", "constant": "PRODUCT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a valid license key that requires a policy scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requirePolicyScope": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "policy scope is required", "constant": "POLICY_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a valid license key that requires a machine scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireMachineScope": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "machine scope is required", "constant": "MACHINE_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Anonymous validates a valid license key that requires a fingerprint scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireFingerprintScope": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.year.from_now",
        "key": "some-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should contain a "license"
    And the JSON response should contain meta with the following:
      """
      { "valid": false, "detail": "fingerprint scope is required", "constant": "FINGERPRINT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: License quick validates their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"

  Scenario: License attempts to quick validate another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1/actions/validate"
    Then the response status should be "403"

  Scenario: License validates their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"

  Scenario: License attempts to validate another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/actions/validate"
    Then the response status should be "403"