@api/v1
Feature: License validation actions

  Background:
    Given the following "plan" rows exist:
      | id                                   | name       |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Standard 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1      |
    Given the following "account" rows exist:
      | name   | slug  | plan_id                              |
      | Test 1 | test1 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Test 2 | test2 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Ent 1  | ent1  | 44c7918c-80ab-4a13-a831-a2c46cda85c6 |
    And I send and accept JSON
    And I send and accept JSON

  # Quick validation
  Scenario: Quick validation endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin validates a license (default version)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a license (v1.2)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.2"
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a license (v1.1)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.1"
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a license (v1.0)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates an isolated license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates a shared license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates a global license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates an isolated license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates a shared license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates a global license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates an isolated license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates a shared license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment quick validates a global license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a check-in license that is valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["*"]
      }
      """
    And the current account has 1 "policies"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should be a "license" with a lastValidated within seconds of "$time.now.iso"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should process 1 "touch-license" job
    And the first "license" should have a lastValidatedAt within seconds of "$time.now.iso"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a check-in license that is overdue
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["license.validation.succeeded"]
      }
      """
    And the current account has 1 "policies"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should be a "license" with a lastValidated within seconds of "$time.now.iso"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is overdue for check in", "code": "OVERDUE" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that is valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["license.validation.succeeded"]
      }
      """
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
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a suspended license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["license.validation.failed"]
      }
      """
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is suspended", "code": "SUSPENDED" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a license belonging to a banned user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["license.validation.failed"] }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is banned", "code": "BANNED" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict floating license that has too many machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": []
      }
      """
    And the current account has 1 "policies"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a non-strict license that has too many machine cores
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "maxMachines": 5,
        "maxCores": 16,
        "floating": true,
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
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (ALWAYS_ALLOW_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "maxMachines": 5,
        "maxCores": 16,
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (ALLOW_1_5X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "maxMachines": 4,
        "maxCores": 16,
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (ALLOW_1_25X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "maxMachines": 8,
        "maxCores": 16,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 6 "machines" for the last "license"
    And all "machines" have the following attributes:
      """
      { "cores": 4 }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (ALLOW_1_25X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" with the following:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "maxMachines": 8,
        "maxCores": 16,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 5 "machines" for the last "license"
    And all "machines" have the following attributes:
      """
      { "cores": 4 }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (ALLOW_1_5X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "maxMachines": 2,
        "maxCores": 16,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (ALLOW_2X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 2,
        "maxCores": 16,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (ALLOW_2X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 2,
        "maxCores": 16,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 24
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many machine cores (NO_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "NO_OVERAGE",
        "maxMachines": 1,
        "maxCores": 8,
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
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "must have at least 1 associated machine", "code": "NO_MACHINES" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "must have exactly 1 associated machine", "code": "NO_MACHINE" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a strict license that has too many processes (NO_OVERAGE overage strategy, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "NO_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 6 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a license by key that is expired (restrict strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "expirationStrategy": "RESTRICT_ACCESS"
      }
      """
    And the current account has 3 "licenses"
    And the current account has 1 "webhook-endpoint"
    And the first "license" has the following attributes:
      """
      { "key": "foo-bar" }
      """
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/foo-bar/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is expired", "code": "EXPIRED" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a license by key that is expired (revoke strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "expirationStrategy": "REVOKE_ACCESS"
      }
      """
    And the current account has 3 "licenses"
    And the current account has 1 "webhook-endpoint"
    And the first "license" has the following attributes:
      """
      { "key": "foo-bar" }
      """
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/foo-bar/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is expired", "code": "EXPIRED" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a license by key that is expired (maintain strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "expirationStrategy": "MAINTAIN_ACCESS"
      }
      """
    And the current account has 3 "licenses"
    And the current account has 1 "webhook-endpoint"
    And the first "license" has the following attributes:
      """
      { "key": "foo-bar" }
      """
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/foo-bar/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is expired", "code": "EXPIRED" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin quick validates a license by key that is expired (allow strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "expirationStrategy": "ALLOW_ACCESS"
      }
      """
    And the current account has 3 "licenses"
    And the current account has 1 "webhook-endpoint"
    And the first "license" has the following attributes:
      """
      { "key": "foo-bar" }
      """
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.ago"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/foo-bar/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is expired", "code": "EXPIRED" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: An admin quick validates a valid license that requires an environment scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireEnvironmentScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin quick validates an isolated license in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "license"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin quick validates a global license in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 "license"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin quick validates a shared license in a shared environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "license"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin quick validates a global license in a shared environment
    Given the current account is "ent1"
    And the current account has 1 "license"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # License validation
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin validates a license (default version)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a license (v1.2)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.2"
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a license (v1.1)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.1"
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a license (v1.0)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates an isolated license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a shared license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a global license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates an isolated license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a shared license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a global license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates an isolated license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a shared license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a global license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should be a "license" with a lastValidated within seconds of "$time.now.iso"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should be a "license" with a lastValidated within seconds of "$time.now.iso"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is overdue for check in", "code": "OVERDUE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is suspended", "code": "SUSPENDED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a license belonging to a banned user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.1.minute.ago" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is banned", "code": "BANNED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that would have too many machines but has overridden max machines
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
        "expiry": "$time.1.day.from_now",
        "maxMachines": 10
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that does not have a machine limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": null,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now",
        "maxMachines": null
      }
      """
    And the current account has 11 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a non-strict license that has too many machine cores
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 5,
        "maxCores": 16,
        "floating": true,
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many machine cores
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 5,
        "maxCores": 16,
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
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 12
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "must have at least 1 associated machine", "code": "NO_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the first "license" has the following attributes:
      """
      { "key": "a-b-c-d-e" }
      """
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/a-b-c-d-e/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "must have exactly 1 associated machine", "code": "NO_MACHINE" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "is expired", "code": "EXPIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: An isolated admin validates a valid license scoped to a isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "license"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "environment": "$environments[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: A shared admin validates a valid license scoped to a isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "license"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "environment": "$environments[0]"
          }
        }
      }
      """
    Then the response status should be "401"

  @ee
  Scenario: A shared admin validates a valid license scoped to a shared environment
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "license"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "environment": "shared"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: A global admin validates a valid license scoped to a nil environment
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 global "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "environment": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: A global admin validates an isolated license scoped to a mismatched environment
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 isolated "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "environment": "$environments[1]"
          }
        }
      }
      """
    Then the response status should be "404"

  @ee
  Scenario: A shared admin validates a global license scoped to a mismatched environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "license"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "environment": "$environments[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "environment scope does not match", "code": "ENVIRONMENT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: A global admin validates a global license scoped to a mismatched environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "environment": "$environements[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "environment scope does not match", "code": "ENVIRONMENT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "product scope does not match", "code": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a valid license scoped to a specific user ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "user": "$users[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a valid license scoped to a specific user email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "user": "$users[1].email"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license scoped to a mismatched user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "user": "$users[2]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "user scope does not match", "code": "USER_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "machine is not activated (does not match any associated machines)", "code": "MACHINE_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID",
        "scope": {
          "fingerprint": "$machines[0].fingerprint"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "fingerprint is not activated (does not match any associated machines)",
        "code": "FINGERPRINT_SCOPE_MISMATCH",
        "scope": {
          "fingerprint": "$machines[1].fingerprint"
        }
      }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates an expired license scoped to a mismatched machine fingerprint (expiration strategy: revoke)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "expirationStrategy": "REVOKE_ACCESS"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.month.ago"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "is expired",
        "code": "EXPIRED",
        "scope": {
          "fingerprint": "$machines[1].fingerprint"
        }
      }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates an expired license scoped to a mismatched machine fingerprint (expiration strategy: restrict)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "expirationStrategy": "RESTRICT_ACCESS"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.month.ago"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "fingerprint is not activated (does not match any associated machines)",
        "code": "FINGERPRINT_SCOPE_MISMATCH",
        "scope": {
          "fingerprint": "$machines[1].fingerprint"
        }
      }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates an expired license scoped to a mismatched machine fingerprint (expiration strategy: maintain)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "expirationStrategy": "MAINTAIN_ACCESS"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.month.ago"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "fingerprint is not activated (does not match any associated machines)",
        "code": "FINGERPRINT_SCOPE_MISMATCH",
        "scope": {
          "fingerprint": "$machines[1].fingerprint"
        }
      }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates an expired license scoped to a mismatched machine fingerprint (expiration strategy: allow)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "expirationStrategy": "ALLOW_ACCESS"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.month.ago"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "fingerprint is not activated (does not match any associated machines)",
        "code": "FINGERPRINT_SCOPE_MISMATCH",
        "scope": {
          "fingerprint": "$machines[1].fingerprint"
        }
      }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint is not activated (has no associated machines)", "code": "NO_MACHINES" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint is not activated (has no associated machine)", "code": "NO_MACHINE" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license scoped to a mismatched policy
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "policy scope does not match", "code": "POLICY_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "product scope does not match", "code": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: An admin validates a valid license that requires an environment scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "requireEnvironmentScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "environment scope is required", "code": "ENVIRONMENT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "product scope is required", "code": "PRODUCT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a valid license that requires a user scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "requireUserScope": true
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "user scope is required", "code": "USER_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a valid license that requires a checksum scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is required", "code": "CHECKSUM_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a valid license that requires a version scope
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "version scope is required", "code": "VERSION_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "policy scope is required", "code": "POLICY_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "machine scope is required", "code": "MACHINE_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint scope is required", "code": "FINGERPRINT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a legacy encrypted license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "LEGACY_ENCRYPT",
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license using scheme RSA_2048_PKCS1_ENCRYPT
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" using "RSA_2048_PKCS1_ENCRYPT"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license using scheme RSA_2048_PKCS1_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license using scheme RSA_2048_PKCS1_PSS_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license using scheme RSA_2048_JWT_RS256
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" using "RSA_2048_JWT_RS256"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license using scheme RSA_2048_PKCS1_SIGN_V2
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN_V2"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN_V2"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: An admin validates a license using scheme ED25519_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "ED25519_SIGN"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: A user validates a license scoped to their own ID
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "user": "$users[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: A user validates a license scoped to their own email
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "user": "$users[1].email"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: A user validates a license scoped to a different user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[2]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "user": "$users[2]"
          }
        }
      }
      """
    Then the response status should be "404"

  Scenario: Admin validates a strict floating license that has too many machines (ALWAYS_ALLOW_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "maxMachines": 5,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 6 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that has too many machines (ALLOW_1_25X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "maxMachines": 4,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 5 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that has too many machines (ALLOW_1_25X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "maxMachines": 4,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 6 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that has too many machines (ALLOW_1_5X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "maxMachines": 4,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 6 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that has too many machines (ALLOW_1_5X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "maxMachines": 2,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 4 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that has too many machines (ALLOW_2X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 2,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 4 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that has too many machines (ALLOW_2X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 2,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 5 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict floating license that has too many machines (NO_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "NO_OVERAGE",
        "maxMachines": 2,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict node-locked license that has too many machines (ALWAYS_ALLOW_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "maxMachines": 1,
        "floating": false,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict node-locked license that has too many machines (ALLOW_2X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 1,
        "floating": false,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict node-locked license that has too many machines (ALLOW_2X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 1,
        "floating": false,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict node-locked license that has too many machines (NO_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "NO_OVERAGE",
        "maxMachines": 1,
        "floating": false,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machines", "code": "TOO_MANY_MACHINES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALWAYS_ALLOW_OVERAGE overage strategy, PER_MACHINE leasing strategy, no scope)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALWAYS_ALLOW_OVERAGE overage strategy, fingerprint scope)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALWAYS_ALLOW_OVERAGE overage strategy, fingerprints scope)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "scope": {
            "fingerprints": ["$machines[0].fingerprint"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALWAYS_ALLOW_OVERAGE overage strategy, machine scope)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALWAYS_ALLOW_OVERAGE overage strategy, v1.1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    And I use API version "1.1"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "constant": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALWAYS_ALLOW_OVERAGE overage strategy, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALWAYS_ALLOW_OVERAGE overage strategy, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_25X_OVERAGE overage strategy, within overage allowance, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 5 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_25X_OVERAGE overage strategy, within overage allowance, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 5 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_25X_OVERAGE overage strategy, exceeded overage allowance, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 6 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_25X_OVERAGE overage strategy, exceeded overage allowance, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 6 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_5X_OVERAGE overage strategy, within overage allowance, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 5 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_5X_OVERAGE overage strategy, within overage allowance, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 5 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_5X_OVERAGE overage strategy, exceeded overage allowance, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_1_5X_OVERAGE overage strategy, exceeded overage allowance, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 4,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_2X_OVERAGE overage strategy, within overage allowance, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_2X_OVERAGE overage strategy, within overage allowance, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_2X_OVERAGE overage strategy, exceeded overage allowance, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 11 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (ALLOW_2X_OVERAGE overage strategy, exceeded overage allowance, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 11 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (NO_OVERAGE overage strategy, PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "NO_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 11 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many processes (NO_OVERAGE overage strategy, PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And the last "policy" has the following attributes:
      """
      {
        "overageStrategy": "NO_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 5,
        "strict": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 11 "processes"
    And all "processes" have the following attributes:
      """
      { "machineId": "$machines[0]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated processes", "code": "TOO_MANY_PROCESSES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many machine cores (ALWAYS_ALLOW_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "maxMachines": 5,
        "maxCores": 16,
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many machine cores (ALLOW_1_5X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "maxMachines": 4,
        "maxCores": 16,
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many machine cores (ALLOW_1_5X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "maxMachines": 2,
        "maxCores": 16,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many machine cores (ALLOW_2X_OVERAGE overage strategy, within overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 2,
        "maxCores": 16,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many machine cores (ALLOW_2X_OVERAGE overage strategy, exceeded overage allowance)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "maxMachines": 2,
        "maxCores": 16,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 24
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin validates a strict license that has too many machine cores (NO_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "overageStrategy": "NO_OVERAGE",
        "maxMachines": 1,
        "maxCores": 8,
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
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 16
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "has too many associated machine cores", "code": "TOO_MANY_CORES" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates an isolated license in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a global license in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 "license"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a shared license in a shared environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a global license in a shared environment
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  # Key validation
  Scenario: Key validation endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key"
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"

  # Versions
  Scenario: Anonymous validates a license (default version)
    Given the current account is "test1"
    And the current account has 1 "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license (v1.2)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I use API version "1.2"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license (v1.1)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I use API version "1.1"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license (v1.0)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "constant": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should be a "license" with a lastValidated within seconds of "$time.now.iso"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_ENCRYPT by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_ENCRYPT"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_ENCRYPT by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_ENCRYPT"
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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_SIGN by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_SIGN by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN"
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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_PSS_SIGN by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_PSS_SIGN by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN"
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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_JWT_RS256 by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_JWT_RS256"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_JWT_RS256 by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_JWT_RS256"
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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_SIGN_V2 by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN_V2"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_SIGN_V2 by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN_V2"
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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN_V2"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN_V2"
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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme ED25519_SIGN by key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "ED25519_SIGN"
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license using scheme ED25519_SIGN by key using the legacy encrypted flag
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" using "ED25519_SIGN"
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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Anonymous validates a valid license key scoped to an environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "environment": null
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/meta/scope/environment"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous validates a valid license key scoped to an isolated environment (with environment header)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "license"
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "environment": "isolated"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous validates a valid license key scoped to an isolated environment (no environment header)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "environment": "$environments[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous validates a valid license key scoped to a shared environment (with environment header)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "license"
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "environment": "$environments[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous validates a valid license key scoped to a shared environment (no environment header)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "environment": "$environments[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous validates a valid license key scoped to a global environment
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "environment": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous validates a license key scoped to a mismatched environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 shared "license"
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "environment": "$environments[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "environment scope does not match", "code": "ENVIRONMENT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "product scope does not match", "code": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "machine is not activated (does not match any associated machines)", "code": "MACHINE_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "machine is not activated (has no associated machine)", "code": "NO_MACHINE" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "machine is not activated (has no associated machines)", "code": "NO_MACHINES" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint is not activated (does not match any associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid fingerprints
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "$machines[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid and invalid fingerprints (matching strategy: MATCH_ANY)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_ANY",
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "foo:bar",
              "baz:qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority valid and some invalid fingerprints (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_MOST",
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "$machines[2].fingerprint",
              "foo:bar",
              "baz:qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of equal valid and invalid fingerprints (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_MOST",
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "foo:bar",
              "baz:qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of some valid and majority invalid fingerprints (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_MOST",
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "foo:bar",
              "baz:qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more fingerprint is not activated (does not match enough associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of an invalid fingerprint (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_MOST",
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "foo:bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint is not activated (does not match any associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid fingerprints (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "machineMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "some-key" }
      """
    And the current account has 3 "machines" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority valid and some invalid fingerprints (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "machineMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "some-key" }
      """
    And the current account has 3 "machines" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "foo:bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of equal valid and invalid fingerprints (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "machineMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "some-key" }
      """
    And the current account has 3 "machines" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "foo:bar",
              "baz:qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of some valid and majority invalid fingerprints (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "machineMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "some-key" }
      """
    And the current account has 3 "machines" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprints": [
              "$machines[0].fingerprint",
              "foo:bar",
              "baz:qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more fingerprint is not activated (does not match at least 2 associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of enough valid and majority invalid fingerprints (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "machineMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "some-key" }
      """
    And the current account has 3 "machines" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "foo:bar",
              "baz:qux",
              "quxx:corge",
              "grault:garply",
              "waldo:fred"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of invalid fingerprints (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "machineMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "some-key" }
      """
    And the current account has 3 "machines" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-key",
          "scope": {
            "fingerprints": [
              "foo:bar",
              "baz:qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more fingerprint is not activated (does not match at least 2 associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of a valid fingerprint (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_MOST",
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid and invalid fingerprints (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_ALL",
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
    And the current account has 3 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "$machines[2].fingerprint",
              "foo:bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more fingerprint is not activated (does not match all associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid fingerprints (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_ALL",
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
    And the current account has 5 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[1].fingerprint",
              "$machines[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of duplicate fingerprints (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "machineMatchingStrategy": "MATCH_ALL",
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
    And the current account has 5 "machines"
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
            "fingerprints": [
              "$machines[0].fingerprint",
              "$machines[0].fingerprint",
              "$machines[0].fingerprint",
              "$machines[0].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an empty array of fingerprints
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
    And the current account has 4 "machines"
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
            "fingerprints": []
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint scope is empty", "code": "FINGERPRINT_SCOPE_EMPTY" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of nil fingerprints
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
    And the current account has 4 "machines"
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
            "fingerprints": [
              null,
              null
            ]
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "cannot be null",
        "source": {
          "pointer": "/meta/scope/fingerprints/0"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of fingerprints belonging to another license
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
    And the current account has 4 "machines"
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
            "fingerprints": [
              "$machines[1].fingerprint",
              "$machines[2].fingerprint",
              "$machines[3].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more fingerprint is not activated (does not match any associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key scoped to a mismatched policy
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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "policy scope does not match", "code": "POLICY_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should not contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "product scope does not match", "code": "PRODUCT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "product scope is required", "code": "PRODUCT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "policy scope is required", "code": "POLICY_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "machine scope is required", "code": "MACHINE_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint scope is required", "code": "FINGERPRINT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a user scope (missing)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "requireUserScope": true }
      """
    And the current account has 3 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]",
        "key": "user-key"
      }
      """
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "user-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "user scope is required", "code": "USER_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a user scope (provided)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "requireUserScope": true }
      """
    And the current account has 3 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]",
        "key": "user-key"
      }
      """
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "user": "$users[1]" },
          "key": "user-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a user scope (mismatch null)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "requireUserScope": true }
      """
    And the current account has 3 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]",
        "key": "user-key"
      }
      """
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "user": null },
          "key": "user-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "user scope does not match", "code": "USER_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a user scope (match null)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "requireUserScope": true }
      """
    And the current account has 3 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": null,
        "key": "user-key"
      }
      """
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "user": null },
          "key": "user-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a user scope (mismatch)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "requireUserScope": true }
      """
    And the current account has 3 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[3]",
        "key": "user-key"
      }
      """
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "user": "$users[1]" },
          "key": "user-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "user scope does not match", "code": "USER_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (missing)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is required", "code": "CHECKSUM_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (match)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license" with the following attributes:
      """
      { "version": "$releases[0].version" }
      """
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should process 1 "touch-license" job
    And the first "license" should have a lastValidatedVersion "$releases[0].version"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key with a checksum scope (multiple matches)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 5 "releases" for the last "product"
    And the first "release" has the following attributes:
      """
      { "version": "1.0.0" }
      """
    And the second "release" has the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the third "release" has the following attributes:
      """
      { "version": "2.0.1" }
      """
    And the fourth "release" has the following attributes:
      """
      { "version": "2.0.1+hotfix" }
      """
    And the fifth "release" has the following attributes:
      """
      { "version": "2.0.0" }
      """
    And the current account has 1 "artifact" for each "release"
    And all "artifacts" have the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license" with the following attributes:
      """
      { "version": "2.0.1+hotfix" }
      """
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should process 1 "touch-license" job
    And the first "license" should have a lastValidatedChecksum "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30"
    And the first "license" should have a lastValidatedVersion "2.0.1+hotfix"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key with a checksum and version scope (multiple matches)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 4 "releases" for the last "product"
    And the first "release" has the following attributes:
      """
      { "version": "1.0.0" }
      """
    And the second "release" has the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the third "release" has the following attributes:
      """
      { "version": "2.0.1" }
      """
    And the fourth "release" has the following attributes:
      """
      { "version": "2.0.0" }
      """
    And the current account has 1 "artifact" for each "release"
    And all "artifacts" have the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "version-checksum-key",
          "scope": {
            "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30",
            "version": "1.0.1"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (null)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": null },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is required", "code": "CHECKSUM_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (mismatch)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "9d537774b45954c6cc5fdfa1ac2ab799dd8643140b8496da84835564fc7bfdb3" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is not valid (does not match any accessible artifacts)", "code": "CHECKSUM_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (match open product)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 licensed "product"
    And the current account has 1 open "product"
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And the first "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "artifact" for the second "release"
    And the second "artifact" has the following attributes:
      """
      { "checksum": "58fc0c07e964e459bcbcea1bf344ece9cb558f1f613620cb87b852995965152e" }
      """
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "58fc0c07e964e459bcbcea1bf344ece9cb558f1f613620cb87b852995965152e" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is not valid (does not match any accessible artifacts)", "code": "CHECKSUM_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (match published and uploaded artifact)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 published "release" for the last "product"
    And the current account has 1 uploaded "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license" with the following attributes:
      """
      { "version": "$releases[0].version" }
      """
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (match published and waiting artifact)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 published "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is not valid (does not match any accessible artifacts)", "code": "CHECKSUM_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (match published and failed artifact)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 published "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is not valid (does not match any accessible artifacts)", "code": "CHECKSUM_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (match draft and uploaded artifact)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 uploaded "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is not valid (does not match any accessible artifacts)", "code": "CHECKSUM_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a checksum scope (match yanked artifact)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireChecksumScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "checksum-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "checksum": "49a01da77a888350f45d329ecd45c3e18cb282f69959b1290a1cee1b26780c30" },
          "key": "checksum-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "checksum scope is not valid (does not match any accessible artifacts)", "code": "CHECKSUM_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (missing)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "version scope is required", "code": "VERSION_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (match)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "version": "1.2.3" },
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license" with the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (null)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "version": null },
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "version scope is required", "code": "VERSION_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (mismatch)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "version": "2.3.4" },
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "version scope is not valid (does not match any accessible releases)", "code": "VERSION_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (match open product)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 licensed "product"
    And the current account has 1 open "product"
    And the current account has 1 "release" for the first "product"
    And the first "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "release" for the second "product"
    And the second "release" has the following attributes:
      """
      { "version": "2.0.0" }
      """
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "version": "2.0.0" },
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "version scope is not valid (does not match any accessible releases)", "code": "VERSION_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (match published release)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 published "release" for the last "product"
    And the last "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "version": "1.2.3" },
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license" with the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (match draft release)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the last "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "version": "1.2.3" },
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "version scope is not valid (does not match any accessible releases)", "code": "VERSION_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key that requires a version scope (match yanked release)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the last "release" has the following attributes:
      """
      { "version": "1.2.3" }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "requireVersionScope": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "key": "version-key" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "scope": { "version": "1.2.3" },
          "key": "version-key"
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "version scope is not valid (does not match any accessible releases)", "code": "VERSION_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License quick validates their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"

  Scenario: License attempts to quick validate another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"

  Scenario: License validates their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"

  Scenario: License validates their license (without permission)
    Given the current account is "test1"
    And the current account has 1 "license" with the following:
      """
      { "permissions": [] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"

  Scenario: License validates their license (with permission)
    Given the current account is "test1"
    And the current account has 1 "license" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"

  Scenario: License attempts to validate another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/actions/validate"
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"

  Scenario: Anonymous validates a license and sends a nonce
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "key": "some-license-key-2"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate" with the following:
      """
      {
        "meta": {
          "nonce": 1574265636
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID",
        "nonce": 1574265636
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates an expired license key and sends a nonce
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "key": "some-license-key-3",
        "expiry": "$time.1.month.ago"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-license-key-3",
          "nonce": 9048238457
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should be a "license" with a lastValidated within seconds of "$time.now.iso"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "is expired",
        "code": "EXPIRED",
        "nonce": 9048238457
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key and sends a nonce
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "key": "some-license-key-3"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "some-license-key-3",
          "nonce": 1574265297
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID",
        "nonce": 1574265297
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key with an entitlement scope (missing all entitlements)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "key": "unentitled-license-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "unentitled-license-key",
          "scope": {
            "entitlements": ["FEATURE_A", "FEATURE_B"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "is missing one or more required entitlements",
        "code": "ENTITLEMENTS_MISSING",
        "scope": {
          "entitlements": ["FEATURE_A", "FEATURE_B"]
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key with an entitlement scope (has some entitlements)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "key": "unentitled-license-key"
      }
      """
    And the first "license" has the following policy entitlements:
      """
      ["ENTITLEMENT_A", "ENTITLEMENT_B"]
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "unentitled-license-key",
          "scope": {
            "entitlements": ["ENTITLEMENT_A", "ENTITLEMENT_B", "ENTITLEMENT_C"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "is missing one or more required entitlements",
        "code": "ENTITLEMENTS_MISSING",
        "scope": {
          "entitlements": ["ENTITLEMENT_A", "ENTITLEMENT_B", "ENTITLEMENT_C"]
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key with an entitlement scope (has all entitlements)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "entitled-license-key"
      }
      """
    And the first "license" has the following license entitlements:
      """
      ["LICENSE_ENTITLEMENT"]
      """
    And the first "license" has the following policy entitlements:
      """
      ["POLICY_ENTITLEMENT"]
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "entitled-license-key",
          "scope": {
            "entitlements": ["LICENSE_ENTITLEMENT", "POLICY_ENTITLEMENT"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID",
        "scope": {
          "entitlements": ["LICENSE_ENTITLEMENT", "POLICY_ENTITLEMENT"]
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key with an entitlement scope (has duplicate entitlements)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "entitled-license-key"
      }
      """
    And the first "license" has the following license entitlements:
      """
      ["LICENSE_ENTITLEMENT"]
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "entitled-license-key",
          "scope": {
            "entitlements": ["LICENSE_ENTITLEMENT", "LICENSE_ENTITLEMENT"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID",
        "scope": {
          "entitlements": ["LICENSE_ENTITLEMENT", "LICENSE_ENTITLEMENT"]
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key with an empty entitlement scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "entitled-license-key"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "entitled-license-key",
          "scope": {
            "entitlements": []
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "entitlements scope is empty",
        "code": "ENTITLEMENTS_SCOPE_EMPTY",
        "scope": {
          "entitlements": []
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a license key using an invalid content type
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "key": "xml-license-key"
      }
      """
    And I send the following headers:
      """
      { "content-type": "vnd.api+xml" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      <validation>
        <meta>
          <key>xml-license-key</key>
        </meta>
      </validation>
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The mime type of the request is not acceptable (check content-type and accept headers)",
        "code": "MIME_TYPE_INVALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  # Expiration basis
  Scenario: Anonymous validates a license key with a validation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_VALIDATION",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": null
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
    Then sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have a 1 year expiry

  Scenario: Product validates a license key with a validation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_VALIDATION",
        "productId": "$products[0]",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": null
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have a 1 year expiry

  Scenario: Anonymous validates a license key with an activation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_ACTIVATION",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": null
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
    Then sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should not have an expiry

  Scenario: Anonymous validates a license key with a validation expiration basis (set)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_VALIDATION",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "2022-01-03T14:18:02.743Z"
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
    Then sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have the expiry "2022-01-03T14:18:02.743Z"

  Scenario: Anonymous validates a license key scoped to an alive machine (by fingerprint)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": "$time.1.hour" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.59.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key scoped to a dead machine (by fingerprint)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": "$time.1.hour" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.2.hours.ago",
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "machine heartbeat is dead",
        "code": "HEARTBEAT_DEAD"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key scoped to an alive machine (by ID)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": "$time.1.hour" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.59.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key scoped to a dead machine (by ID)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": "$time.1.hour" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.2.hours.ago",
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "machine heartbeat is dead",
        "code": "HEARTBEAT_DEAD"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key that requires a machine heartbeat (alive)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "heartbeatDuration": "$time.1.hour",
        "requireHeartbeat": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.10.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key that requires a machine heartbeat (dead)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "heartbeatDuration": "$time.1.hour",
        "requireHeartbeat": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.2.hours.ago",
        "licenseId": "$licenses[0]"
      }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "machine heartbeat is dead",
        "code": "HEARTBEAT_DEAD"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key that requires a machine heartbeat (not started)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      {
        "heartbeatDuration": "$time.1.hour",
        "requireHeartbeat": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key with optional machine heartbeat (not started)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      {
        "heartbeatDuration": "$time.1.hour",
        "requireHeartbeat": false
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key that requires a machine heartbeat (not started, FROM_CREATION basis)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      {
        "heartbeatDuration": "$time.1.hour",
        "heartbeatBasis": "FROM_CREATION",
        "requireHeartbeat": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": true,
        "detail": "is valid",
        "code": "VALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key that requires a machine heartbeat (not started, FROM_FIRST_PING basis)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      {
        "heartbeatDuration": "$time.1.hour",
        "heartbeatBasis": "FROM_FIRST_PING",
        "requireHeartbeat": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "machine heartbeat is required",
        "code": "HEARTBEAT_NOT_STARTED"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: Anonymous validates a license key that requires a machine heartbeat (by ID)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      {
        "heartbeatDuration": "$time.1.hour",
        "heartbeatBasis": "FROM_FIRST_PING",
        "requireHeartbeat": true
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "machine": "$machines[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      {
        "valid": false,
        "detail": "machine heartbeat is required",
        "code": "HEARTBEAT_NOT_STARTED"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: A user validates a license key scoped to their own ID
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "user": "$users[1]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """

  Scenario: A user validates a license key scoped to their own email
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "user": "$users[1].email"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """

  Scenario: A user validates a license key scoped to a different user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[2]",
        "expiry": "$time.1.year.from_now"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key",
          "scope": {
            "user": "$users[2]"
          }
        }
      }
      """
    Then the response status should be "403"

  @ce
  Scenario: Admin validates a license key in an environment
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "invalid" }
      """
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is unsupported",
        "code": "ENVIRONMENT_NOT_SUPPORTED",
        "source": {
          "header": "Keygen-Environment"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a license key in an invalid environment
    Given the current account is "ent1"
    And the current account has 1 "license"
    And I am an admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "invalid" }
      """
    When I send a POST request to "/accounts/ent1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "environment is invalid",
        "code": "ENVIRONMENT_INVALID",
        "source": {
          "header": "Keygen-Environment"
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates an isolated license key in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "license"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a shared license key in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "license"
    And the current account has 1 isolated "admin"
    And the current environment is "isolated"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a global license key in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 "license"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a shared license key in a shared environment
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "license"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates an isolated license key in a shared environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "license"
    And the current environment is "shared"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin validates a global license key in a shared environment
    Given the current account is "ent1"
    And the current account has 1 "license"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates an isolated license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
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
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a shared license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
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
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a global license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
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
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates an isolated license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
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
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "does not exist", "code": "NOT_FOUND" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a shared license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
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
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a global license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
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
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates an isolated license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a shared license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment validates a global license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "$licenses[0].key"
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid components (matching strategy: MATCH_ANY)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ANY" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "$components[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority valid components (matching strategy: MATCH_ANY)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ANY" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of invalid components (matching strategy: MATCH_ANY)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ANY" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "foo",
              "bar",
              "baz"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match any associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority invalid components (matching strategy: MATCH_ANY)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ANY" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "foo",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of misassociated components (matching strategy: MATCH_ANY)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ANY" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[3].fingerprint",
              "$components[4].fingerprint",
              "$components[5].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match any associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid components (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "$components[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority valid components (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of invalid components (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "foo",
              "bar",
              "baz"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match at least 2 associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority invalid components (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "foo",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match at least 2 associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of misassociated components (matching strategy: MATCH_TWO)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_TWO" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[3].fingerprint",
              "$components[4].fingerprint",
              "$components[5].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match at least 2 associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid components (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_MOST" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "$components[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority valid components (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_MOST" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of invalid components (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_MOST" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "foo",
              "bar",
              "baz"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match enough associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority invalid components (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_MOST" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "foo",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match enough associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of misassociated components (matching strategy: MATCH_MOST)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_MOST" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[3].fingerprint",
              "$components[4].fingerprint",
              "$components[5].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match enough associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of valid components (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ALL" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "$components[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": true, "detail": "is valid", "code": "VALID" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority valid components (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ALL" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match all associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of invalid components (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ALL" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "foo",
              "bar",
              "baz"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match all associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of majority invalid components (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ALL" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[0].fingerprint",
              "foo",
              "bar"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match all associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of misassociated components (matching strategy: MATCH_ALL)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "componentMatchingStrategy": "MATCH_ALL" }
      """
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "$machines[0].fingerprint",
            "components": [
              "$components[3].fingerprint",
              "$components[4].fingerprint",
              "$components[5].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "one or more component is not activated (does not match all associated components)", "code": "COMPONENTS_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of components without a fingerprint scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "$components[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint scope is required when using the components scope", "code": "FINGERPRINT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of components with a fingerprints scope
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "components" for each "machine"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprints": ["$machines[0].fingerprint"],
            "components": [
              "$components[0].fingerprint",
              "$components[1].fingerprint",
              "$components[2].fingerprint"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint scope is required when using the components scope", "code": "FINGERPRINT_SCOPE_REQUIRED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous validates a valid license key scoped to an array of components with an invalid fingerprint
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy" with the following:
      """
      { "key": "component-key" }
      """
    And the current account has 1 "machine" for the last "license"
    When I send a POST request to "/accounts/test1/licenses/actions/validate-key" with the following:
      """
      {
        "meta": {
          "key": "component-key",
          "scope": {
            "fingerprint": "foo",
            "components": [
              "bar",
              "baz",
              "qux"
            ]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should contain a "license"
    And the response body should contain meta which includes the following:
      """
      { "valid": false, "detail": "fingerprint is not activated (does not match any associated machines)", "code": "FINGERPRINT_SCOPE_MISMATCH" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
