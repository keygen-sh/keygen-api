@api/v1
Feature: Update machine

  Background:
    Given the following "accounts" exist:
      | Company | Name  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin updates a machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "name": "Home iMac" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the name "Home iMac"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Admin attempts to update a machine's fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "fingerprint": "b7:WE:YV:oR:jU:Bc:d6:Wk:Yo:Po:Mu:oN:4Q:bC:pi" } }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Product updates a machine for their product
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    And the current product has 1 "machine"
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "name": "Work MacBook Pro" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the name "Work MacBook Pro"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Product attempts to update a machine for another product
    Given the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "name": "Office PC" } }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs

  Scenario: User updates a machine's name for their license
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": $users[1].id }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": $licenses[0].id }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "name": "Office Mac" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "machine" with the name "Office Mac"
    And sidekiq should have 2 "webhook" jobs

  Scenario: User updates a machine's fingerprint for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": $users[1].id }
      """
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": $licenses[0].id }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "fingerprint": "F8:2B:DV:tH:Tm:AY:uG:QG:VJ:ct:N6:nK:WF:tq:vr" } }
      """
    Then the response status should be "400"

  Scenario: User attempts to update a machine for another user
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "name": "Office Mac" } }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Anonymous user attempts to update a machine for their account
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "machines"
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "name": "iPad 4" } }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin attempts to update a machine for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a PATCH request to "/machines/$0" with the following:
      """
      { "machine": { "name": "PC" } }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
