@api/v1
Feature: Update machine

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
    When I send a PATCH request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Admin updates a machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "name": "Home iMac"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the name "Home iMac"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a machine
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "name": "Home iMac"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Sales updates a machine
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "name": "Home iMac"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Support updates a machine
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "name": "Home iMac"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Admin removes a machine's IP address
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "ip": "192.168.1.1"
      }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "ip": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with a nil ip
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a machine's core count to an amount that is permissable
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 1,
        "maxCores": 12,
        "concurrent": false,
        "floating": false,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "cores": 12
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the cores "12"
    And the first "license" should have a correct machine core count
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a non-concurrent machine's core count to an amount that exceeds their maximum core limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 2,
        "maxCores": 12,
        "concurrent": false,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "cores": 32
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "machine core count has exceeded maximum allowed by current policy (12)",
        "code": "MACHINE_CORE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a concurrent-capable machine's core count to an amount that exceeds their maximum core limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 5,
        "maxCores": 12,
        "concurrent": true,
        "floating": true,
        "strict": false
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "$machines[0].id",
          "attributes": {
            "cores": 32
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the cores "32"
    And the first "license" should have a correct machine core count
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update a machine's fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "b7:WE:YV:oR:jU:Bc:d6:Wk:Yo:Po:Mu:oN:4Q:bC:pi"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates a machine for their product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    And the current product has 1 "machine"
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "name": "Work MacBook Pro"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the name "Work MacBook Pro"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a machine for another product
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "name": "Office PC"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a machine's name that belongs to a unprotected license
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]", "protected": false }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "name": "Office Mac"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the name "Office Mac"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a machine's name that belongs to a protected license
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]", "protected": true }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "name": "Office Mac"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a machine's fingerprint for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "F8:2B:DV:tH:Tm:AY:uG:QG:VJ:ct:N6:nK:WF:tq:vr"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a machine for another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "users"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      { "machine": { "name": "Office Mac" } }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous user attempts to update a machine for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "machines"
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "name": "iPad 4"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update a machine for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/machines/$0" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "name": "PC"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
