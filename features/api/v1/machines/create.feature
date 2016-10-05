@api/v1
Feature: Create machine

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin creates a machine for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    And I use my auth token
    When I send a POST request to "/machines" with the following:
      """
      { "machine": { "license": "$licenses[0]", "fingerprint": "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC" } }
      """
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC"
    And sidekiq should have 2 "webhook" jobs

  Scenario: Admin creates a machine with missing fingerprint
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    And I use my auth token
    When I send a POST request to "/machines" with the following:
      """
      { "machine": { "license": "$licenses[0]" } }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin creates a machine with missing license
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    And I use my auth token
    When I send a POST request to "/machines" with the following:
      """
      { "machine": { "fingerprint": "qv:8W:qh:Fx:Ua:kN:LY:fj:yG:8H:Ar:N8:KZ:Uk:ge" } }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs

  Scenario: User creates a machine for their license
    Given I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "license"
    And the current user has 1 "license"
    And I use my auth token
    When I send a POST request to "/machines" with the following:
      """
      { "machine": { "license": "$licenses[0]", "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE" } }
      """
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE"
    And sidekiq should have 2 "webhook" jobs

  Scenario: User creates a machine for another user's license
    Given I am on the subdomain "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/machines" with the following:
      """
      { "machine": { "license": "$licenses[0]", "fingerprint": "oD:aP:3o:GD:vi:H3:Zw:up:h8:3a:hC:MD:2e:4d:cr" } }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Unauthenticated user attempts to create a machine
    Given I am on the subdomain "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    When I send a POST request to "/machines" with the following:
      """
      { "machine": { "license": "$licenses[0]", "key": "fw:8v:uU:bm:Wt:Zf:rL:e7:Xg:mg:8x:NV:hT:Ej:jK" } }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin of another account attempts to create a machine
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the current account has 10 "webhookEndpoints"
    And the current account has 1 "license"
    And I use my auth token
    When I send a POST request to "/machines" with the following:
      """
      { "machine": { "license": "$licenses[0]", "key": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw" } }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
