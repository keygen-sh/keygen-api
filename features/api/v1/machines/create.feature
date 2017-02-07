@api/v1
Feature: Create machine

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin creates a machine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC"
          },
          "relationships": {
            "license": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a machine with missing fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "relationships": {
            "license": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a machine with missing license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "qv:8W:qh:Fx:Ua:kN:LY:fj:yG:8H:Ar:N8:KZ:Uk:ge"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User creates a machine for their license
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "license"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE"
          },
          "relationships": {
            "license": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: User hits the machine limit for their license
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "maxMachines": 3 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE"
          },
          "relationships": {
            "license": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User creates a machine for another user's license
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "oD:aP:3o:GD:vi:H3:Zw:up:h8:3a:hC:MD:2e:4d:cr"
          },
          "relationships": {
            "license": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Unauthenticated user attempts to create a machine
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "license"
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "fw:8v:uU:bm:Wt:Zf:rL:e7:Xg:mg:8x:NV:hT:Ej:jK"
          },
          "relationships": {
            "license": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin of another account attempts to create a machine
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 10 "webhookEndpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw"
          },
          "relationships": {
            "license": {
              "data": {
                "type": "licenses",
                "id": "$licenses[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
