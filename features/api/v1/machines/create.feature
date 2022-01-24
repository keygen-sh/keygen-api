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
    And the current account should have 0 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a machine for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
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

  Scenario: Sales creates a machine for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
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

  Scenario: Support attempts to create a machine for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
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
    Then the response status should be "403"

  Scenario: Admin creates a machine for their account with a UUID fingerprint
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
            "fingerprint": "977f1752-d6a9-4669-a6af-b039154ec40f"
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
    And the JSON response should be a "machine" with the fingerprint "977f1752-d6a9-4669-a6af-b039154ec40f"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for their account with a fingerprint matching another machine's ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "$machines[0]"
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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for their account with a fingerprint matching a reserved word
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "actions"
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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

    # Sanity check on license's machine counter
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "machines": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/machines" },
          "meta": { "cores": 0, "count": 1 }
        }
      }
      """

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a concurrent floating license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a non-concurrent floating license that does not have a limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": null,
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
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a non-concurrent floating license that has almost reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
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
    And the current account has 4 "machines"
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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a non-concurrent floating license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
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
        "detail": "machine count has exceeded maximum allowed by current policy (5)",
        "code": "MACHINE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a concurrent node-locked license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 1,
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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a non-concurrent node-locked license that has already reached its limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "maxMachines": 1,
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
        "detail": "machine count has exceeded maximum allowed by current policy (1)",
        "code": "MACHINE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a non-concurrent node-locked license that does not have a limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
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
    And the current account has 3 "machines"
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
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a machine with a fingerprint from another license's machine for a license-scoped fingerprint uniqueness strategy
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_LICENSE" }
      """
    And the current account has 2 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "protected": true
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
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
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a machine with a fingerprint from another license's machine for a policy-scoped fingerprint uniqueness strategy (same policy)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_POLICY" }
      """
    And the current account has 2 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "protected": true
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
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
        "detail": "has already been taken for this policy",
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
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a machine with a fingerprint from another license's machine for a policy-scoped fingerprint uniqueness strategy (different policy)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "policies"
    And all "policies" have the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_POLICY" }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "protected": true
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "policyId": "$policies[1]",
        "protected": true
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
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
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE"
    And the current token should have the following attributes:
      """
      {
        "activations": 1
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a machine with a fingerprint from another license's machine for a product-scoped fingerprint uniqueness strategy (same product)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      {
        "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT",
        "productId": "$products[0]"
      }
      """
    And the current account has 2 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "protected": true
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
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
        "detail": "has already been taken for this product",
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
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a machine with a fingerprint from another license's machine for a product-scoped fingerprint uniqueness strategy (different product)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT",
        "productId": "$products[0]"
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT",
        "productId": "$products[1]"
      }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "protected": true
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "policyId": "$policies[1]",
        "protected": true
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
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
    Then the response status should be "201"
    And the JSON response should be a "machine" with the fingerprint "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE"
    And the current token should have the following attributes:
      """
      {
        "activations": 1
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a machine with a fingerprint from another license's machine for a account-scoped fingerprint uniqueness strategy (same account)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_ACCOUNT" }
      """
    And the current account has 2 "licenses"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "protected": true
      }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
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
        "detail": "has already been taken for this account",
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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a floating license that has not reached its core limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 10,
        "maxCores": 32,
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
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 12
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
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "machine" with the cores "12"
    And the first "license" should have a correct machine core count
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a non-concurrent floating license that has exceeded its core limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 10,
        "maxCores": 32,
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 12
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
        "detail": "machine core count has exceeded maximum allowed by current policy (32)",
        "code": "MACHINE_CORE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a non-concurrent floating license with a max cores override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 10,
        "maxCores": 32,
        "concurrent": false,
        "floating": true,
        "strict": true
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "maxCores": 64
      }
      """
    And the current account has 4 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 32
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
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "machine" with the cores "32"
    And the first "license" should have a correct machine core count
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a concurrent floating license that has exceeded its core limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 10,
        "maxCores": 32,
        "concurrent": true,
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
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "cores": 8
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 16
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
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "machine" with the cores "16"
    And the first "license" should have a correct machine core count
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a node-locked license that has not reached its core limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 1,
        "maxCores": 8,
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
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 8
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
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "machine" with the cores "8"
    And the first "license" should have a correct machine core count
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine for a node-locked license that has exceeded its core limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 1,
        "maxCores": 8,
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
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 12
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
        "detail": "machine core count has exceeded maximum allowed by current policy (8)",
        "code": "MACHINE_CORE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine with an invalid core count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 0
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
        "detail": "must be greater than or equal to 1",
        "code": "CORES_INVALID",
        "source": {
          "pointer": "/data/attributes/cores"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a machine with a large core count but policy has no maximum
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
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 2147483647
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
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "machine" with the cores "2147483647"
    And the first "license" should have a correct machine core count
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  # Expiration basis
  Scenario: License activates a machine with an activation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policies"
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
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 2147483647
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
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have a 1 year expiry

  Scenario: Product activates a machine with an activation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_ACTIVATION",
        "duration": $time.1.month
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
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" jobs
    And the first "license" should have a 1 month expiry

  Scenario: License activates a machine with a validation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policies"
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
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 2147483647
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
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should not have an expiry

  Scenario: License activates a machine with an activation expiration basis (set)
    Given the current account is "test1"
    And the current account has 1 "policies"
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
        "expiry": "2022-01-03T14:18:02.743Z"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "attributes": {
            "fingerprint": "Pm:L2:UP:ti:9Z:eJ:Ts:4k:Zv:Gn:LJ:cv:sn:dW:hw",
            "cores": 2147483647
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
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have the expiry "2022-01-03T14:18:02.743Z"

  Scenario: License activates a machine with a pre-determined ID
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "00000000-2521-4033-9f4f-3675387016f7",
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
    And the JSON response should be a "machine" with the id "00000000-2521-4033-9f4f-3675387016f7"
    And the current account should have 1 "machine"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job

  Scenario: License activates a machine with a pre-determined ID (conflict)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "id": "00000000-2521-4033-9f4f-3675387016f7" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "00000000-2521-4033-9f4f-3675387016f7",
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
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must not conflict with another machine",
        "source": {
          "pointer": "/data/id"
        },
        "code": "ID_CONFLICT"
      }
      """
    And the current account should have 1 "machine"

  Scenario: License activates a machine with a pre-determined ID (bad ID)
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/machines" with the following:
      """
      {
        "data": {
          "type": "machines",
          "id": "1",
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
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid UUID",
        "source": {
          "pointer": "/data/id"
        },
        "code": "ID_INVALID"
      }
      """
    And the current account should have 0 "machines"

  # Authentication schemes
  #
  Scenario: License activates a machine with a token (auth strategy allowed)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "TOKEN" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: License activates a machine with a token (auth strategy not allowed)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "KEY" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "Token authentication is not allowed by policy",
        "code": "TOKEN_NOT_ALLOWED"
      }
      """

  Scenario: License activates a machine with their key (auth strategy allowed)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "KEY" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
    And I authenticate with my license key
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: License activates a machine with their key (auth strategy not allowed)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "TOKEN" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
    And I authenticate with my license key
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "License key authentication is not allowed by policy",
        "code": "LICENSE_NOT_ALLOWED"
      }
      """

  Scenario: License activates a machine with a token (mixed auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "MIXED" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: License activates a machine with their key (mixed auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "MIXED" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
    And I authenticate with my license key
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: License activates a machine with a token (no auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "NONE" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "Token authentication is not allowed by policy",
        "code": "TOKEN_NOT_ALLOWED"
      }
      """

  Scenario: License activates a machine with their key (no auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "licenseAuthStrategy": "NONE" }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a license of account "test1"
    And I authenticate with my license key
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
              "data": { "type": "licenses", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "License key authentication is not allowed by policy",
        "code": "LICENSE_NOT_ALLOWED"
      }
      """
