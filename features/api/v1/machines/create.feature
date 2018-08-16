@api/v1
Feature: Create machine

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
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines"
    Then the response status should be "403"

  Scenario: Admin creates a machine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
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
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a machine with missing fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
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
    And the current account has 2 "webhook-endpoints"
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

  Scenario: Admin creates a machine with an invalid license UUID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
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
                "id": "$users[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User creates a machine for their license
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
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

  Scenario: User creates a machine for their license with a protected policy
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "license"
    And the current user has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": true }
      """
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
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job

  Scenario: User creates a machine for an unprotected license
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "license"
    And the current user has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": false }
      """
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

  Scenario: License creates a machine for their license
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "licenses"
    And I am a license of account "test1"
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
    And the current token should have the following attributes:
      """
      {
        "activations": 1
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: License creates a machine for a protected license
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": true }
      """
    And I am a license of account "test1"
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
    And the current token should have the following attributes:
      """
      {
        "activations": 1
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: License creates a machine for a protected license but they've hit their activation limit
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": true }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      {
        "maxActivations": 1,
        "activations": 1
      }
      """
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
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "exceeds maximum allowed (1)",
        "code": "ACTIVATIONS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/activations"
        }
      }
      """
    And the current token should have the following attributes:
      """
      {
        "activations": 1
      }
      """
    And the current account should have 0 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: License creates a machine for their license with a duplicate fingerprint
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "machine"
    And all "machine" have the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      {
        "maxActivations": 1,
        "activations": 0
      }
      """
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
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "has already been taken",
        "code": "FINGERPRINT_TAKEN",
        "source": {
          "pointer": "/data/attributes/fingerprint"
        }
      }
      """
    And the current token should have the following attributes:
      """
      {
        "activations": 0
      }
      """
    And the current account should have 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: License creates a machine for their license with a blank fingerprint
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "protected": true }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And the current token has the following attributes:
      """
      {
        "maxActivations": 1,
        "activations": 1
      }
      """
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": ""
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
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "can't be blank",
        "code": "FINGERPRINT_BLANK",
        "source": {
          "pointer": "/data/attributes/fingerprint"
        }
      }
      """
    And the current token should have the following attributes:
      """
      {
        "activations": 1
      }
      """
    And the current account should have 0 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: License creates a machine for another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I am a license of account "test1"
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
                "id": "$licenses[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current token should have the following attributes:
      """
      {
        "activations": 0
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product creates a machine associated to a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "productId": "$products[1]"
      }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "policyId": "$policies[1]"
      }
      """
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
                "id": "$licenses[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  # FIXME(ezekg) I'm still unsure how this happened, but this happened in the production
  #              env. I'm assuming that the policy had been queued for deletion, but
  #              maybe wasn't fully deleted at the time they attempted to create a new
  #              machine? Either way, somehow they managed to cause a license to not
  #              have a valid policy associated with it.
  Scenario: User creates a machine associated with a license that has an invalid policy
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "policy"
    And the current account has 1 "license"
    And the current user has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "policyId": null }
      """
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: User creates a machine for another user's license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
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
    And the current account has 2 "webhook-endpoints"
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
    And the current account has 10 "webhook-endpoints"
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

  Scenario: Admin creates a machine for a concurrent floating license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 5,
        "concurrent": true,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 5 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
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
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a machine for a non-concurrent floating license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 5,
        "concurrent": false,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 5 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
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
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "machine count has reached maximum allowed by current policy (5)",
        "code": "MACHINE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job

  Scenario: Admin creates a machine for a concurrent node-locked license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": null,
        "concurrent": true,
        "floating": false,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
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
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a machine for a non-concurrent node-locked license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "webhook-endpoint"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": null,
        "concurrent": false,
        "floating": false,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
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
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "machine count has reached maximum allowed by current policy (1)",
        "code": "MACHINE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job
