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
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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
    And sidekiq should have 0 "metric" job

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
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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
