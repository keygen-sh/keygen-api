@api/v1
Feature: Create license
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

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should be "403"

  Scenario: Admin creates a license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "owner": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with a key that is not nil
    And the response body should be a "license" with the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """
    And the current account should have 1 "license"
    And the first "license" should have 1 "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license for a user of their account (v1.5)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    And I use API version "1.5"
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with a key that is not nil
    And the response body should be a "license" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/user" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """
    And the current account should have 1 "license"
    And the first "license" should have 1 "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license with a null key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": null
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with a key that is not nil
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license with empty metadata
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {}
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license with null metadata
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": null
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a license for a user of their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[2]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"

  Scenario: Sales creates a license for a user of their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[2]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"

  Scenario: Support attempts to create a license for a user of their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[2]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Read-only attempts to create a license for a user of their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[2]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin creates a named license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Some License Name"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the name "Some License Name"
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin creates a license for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
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
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin creates a license for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
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
          "pointer": "/data/relationships/environment"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a license for an isolated environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a license for a shared environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a license for the global environment
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Global License"
          },
          "relationships": {
            "environment": {
              "data": null
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an isolated license for a policy in the global environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 global "policy"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
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
        "detail": "must be compatible with policy environment",
        "code": "ENVIRONMENT_NOT_ALLOWED",
        "source": {
          "pointer": "/data/relationships/environment"
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a shared license for a policy in the global environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 global "policy"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a global license for a policy in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" for the first "environment"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Mixed License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
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
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a global license for a policy in a shared environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy" for the first "environment"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Mixed License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
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
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates an isolated license for a user in the global environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 global "user"
    And I am an admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "user": {
              "data": { "type": "users", "id": "$users[1]" }
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
        "detail": "must be compatible with owner environment",
        "code": "ENVIRONMENT_NOT_ALLOWED",
        "source": {
          "pointer": "/data/relationships/environment"
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a shared license for a user in the global environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 global "user"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            },
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "user": {
              "data": { "type": "users", "id": "$users[1]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a global license for a user in an isolated environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "user" for the first "environment"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Mixed License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "user": {
              "data": { "type": "users", "id": "$users[1]" }
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
        "detail": "must be compatible with owner environment",
        "code": "ENVIRONMENT_NOT_ALLOWED",
        "source": {
          "pointer": "/data/relationships/environment"
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a global license for a user in a shared environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "user" for the first "environment"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Mixed License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "user": {
              "data": { "type": "users", "id": "$users[1]" }
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
        "detail": "must be compatible with owner environment",
        "code": "ENVIRONMENT_NOT_ALLOWED",
        "source": {
          "pointer": "/data/relationships/environment"
        }
      }
      """
    And the response should contain a valid signature header for "ent1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Environment creates an isolated license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
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
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an isolated license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      { "name": "Isolated License" }
      """
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a shared license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[1]"
              }
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a global license (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          },
          "relationships": {
            "environment": {
              "data": null
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a shared license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      { "name": "Shared License" }
      """
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an isolated license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[1]"
              }
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a global license (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Global License"
          },
          "relationships": {
            "environment": {
              "data": null
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a global license (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Global License"
          },
          "relationships": {
            "environment": {
              "data": null
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped license for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped license for their account (null group)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "group": {
              "data": null
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": null
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped license for their account (invalid group)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "group": {
              "data": { "type": "groups", "id": "d03322b2-765e-4220-8f50-3cdc1f2472cb" }
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
        "detail": "must exist",
        "code": "GROUP_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped license for their account (limit exceeded, explicit group)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "group"
    And the last "group" has the following attributes:
      """
      { "maxLicenses": 1 }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
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
        "detail": "license count has exceeded maximum allowed by current group (1)",
        "code": "GROUP_LICENSE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped license for their account (limit exceeded, inherited group)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "group"
    And the last "group" has the following attributes:
      """
      { "maxLicenses": 1 }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "user": {
              "data": { "type": "users", "id": "$users[1]" }
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
        "detail": "license count has exceeded maximum allowed by current group (1)",
        "code": "GROUP_LICENSE_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped license for their account (inherited from user)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "group"
    And the last "group" has the following attributes:
      """
      { "maxMachines": 1 }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "user": {
              "data": { "type": "users", "id": "$users[1]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a grouped license for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "policy"
    And the current account has 1 isolated "group"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses?environment=isolated" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Grouped License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        },
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates a grouped license for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the last "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a grouped license for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "group"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Group License"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            },
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
            },
            "user": {
              "data": { "type": "users", "id": "$users[1]" }
            }
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
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license for a user of their account with a key that contains a null byte
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "$null_byte"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The request could not be completed because it contains an unexpected null byte (check encoding)",
        "code": "ENCODING_INVALID"
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with an invalid policy for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "4796e950-0dcf-4bab-9443-8b406889356e"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response should contain a valid signature header for "test1"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "POLICY_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with an empty owner
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "owner": {},
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """"
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "pointer": "/data/relationships/owner/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a false owner
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "owner": false,
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """"
      {
        "title": "Bad request",
        "detail": "type mismatch (received boolean expected object)",
        "source": {
          "pointer": "/data/relationships/owner"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a null owner (relationship)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "owner": null,
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a null owner (linkage)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "owner": {
              "data": null
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license for an invalid owner of their account (default)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "owner": {
              "data": {
                "type": "users",
                "id": "4796e950-0dcf-4bab-9443-8b406889356e"
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
        "detail": "must exist",
        "code": "OWNER_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/owner"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license for an invalid owner of their account (v1.6)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    And I use API version "1.6"
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "owner": {
              "data": {
                "type": "users",
                "id": "4796e950-0dcf-4bab-9443-8b406889356e"
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
        "detail": "must exist",
        "code": "OWNER_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/owner"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license for an invalid user of their account (v1.5)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    And I use API version "1.5"
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "4796e950-0dcf-4bab-9443-8b406889356e"
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
        "detail": "must exist",
        "code": "USER_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/user"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with metadata for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "fooBarBaz": "Qux"
            }
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      {
        "metadata": {
          "fooBarBaz": "Qux"
        }
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with nested metadata
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "object": {
                "key": "value"
              },
              "array": [
                "foo",
                "bar",
                "baz",
                "qux"
              ]
            }
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following "metadata":
      """
      {
        "object": {
          "key": "value"
        },
        "array": [
          "foo",
          "bar",
          "baz",
          "qux"
        ]
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with complex nested metadata
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "key": ["value"],
              "object": {
                "key": { "k": "v" }
              },
              "array": [
                { "foo": 1 },
                { "bar": 2 },
                { "baz": 3 }
              ]
            }
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following "metadata":
      """
      {
        "key": ["value"],
        "object": {
          "key": { "k": "v" }
        },
        "array": [
          { "foo": 1 },
          { "bar": 2 },
          { "baz": 3 }
        ]
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with too complex nested metadata
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "key": ["value"],
              "object": {
                "key": { "k": "v" }
              },
              "array": [
                [0],
                [{ "foo": 1 }, 2, [3]]
              ]
            }
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "maximum depth of 2 exceeded",
        "source": {
          "pointer": "/data/attributes/metadata/array/1/0"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with metadata for their account and the keys should be transformed to camelcase
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "example_key_1": 1,
              "ExampleKey2": 2,
              "exampleKey3": 3,
              "example key 4": 4
            }
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      {
        "metadata": {
          "exampleKey1": 1,
          "exampleKey2": 2,
          "exampleKey3": 3,
          "exampleKey4": 4
        }
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a pre-determined expiry
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with an expiry "2016-09-05T22:53:37.000Z"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a-license-key"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the key "a-license-key"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "key": "a-duplicate-key"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a-duplicate-key"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a pre-determined key that conflicts with a license ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "$licenses[2].id"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a pre-determined UUID key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the key "977f1752-d6a9-4669-a6af-b039154ec40f"
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate license of another account with a pre-determined UUID key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the account "test2" has 1 "policy"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "id": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxMachines": 3,
        "maxCores": 32,
        "maxUses": 100
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with key "977f1752-d6a9-4669-a6af-b039154ec40f"
    And the response body should be a "license" with maxMachines "3"
    And the response body should be a "license" with maxCores "32"
    And the response body should be a "license" with maxUses "100"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate license of another account with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the account "test2" has 1 "policy"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "key": "a-duplicate-key"
      }
      """
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      { "maxMachines": 3 }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a-duplicate-key"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxMachines "3"
    And the response body should be a "license" with the key "a-duplicate-key"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a legacy encrypted license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "LEGACY_ENCRYPT",
        "encrypted": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the scheme "LEGACY_ENCRYPT"
    And the response body should be a "license" that is encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a legacy encrypted license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "LEGACY_ENCRYPT",
        "encrypted": true,
        "strict": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a-legacy-key"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot be specified for a legacy encrypted license",
        "code": "KEY_NOT_SUPPORTED",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_ENCRYPT without seed data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_ENCRYPT",
        "duration": 2895149
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_ENCRYPT" key with the following dataset:
      """
      {
        "id": "$licenses[0].id",
        "created": "$licenses[0].created_at",
        "duration": 2895149,
        "expiry": "$licenses[0].expiry"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_ENCRYPT with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_ENCRYPT"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-encrypted-payload-here"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the encrypted key "some-encrypted-payload-here" using "RSA_2048_PKCS1_ENCRYPT"
    And the response body should be a "license" with the scheme "RSA_2048_PKCS1_ENCRYPT"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_ENCRYPT with a key that is too large
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_ENCRYPT"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-payload-that-is-too-large-for-encrypting-with-rsa-2048-3dd00576de47b1994e893e5ad0fd9365a574afaff388d8c8363546fa537ac6806b834be964b1ae5ae4aea3650ec8e7c3a65a014a80b82ad71242ae8946bddcba6b6744b01b570d791f605ee5ae5ce06d1f13846119da9efb3da4461d2acf31ff0d624de3b50c621629a979cca9865aa195e89b47beed3d4804aa3ee3a237ddfab7a67905282117d1b34b023ce3ff6518b2fd729547e5a7fae65b6094ba94bf5a768ff4bf668ecc8bb17e5458bc8e36982bc3a366f7560a9d266aa1ad391fe84cad07c92283858cf42a460a1f83450b376b0b58089288cc918991909586d8726a94f0075fdc76e383556be744748991d48cf87aff3a"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "key exceeds maximum byte length (max size of 245 bytes)",
        "code": "KEY_BYTE_SIZE_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_SIGN for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0].id",
        "scheme": "RSA_2048_PKCS1_SIGN",
        "duration": null
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_SIGN" key with the following dataset:
      """
      {
        "account": { "id": "$accounts[0].id" },
        "product": { "id": "$products[0].id" },
        "policy": {
          "id": "$policies[0].id",
          "duration": null
        },
        "user": {
          "id": "$users[1].id",
          "email": "$users[1].email"
        },
        "license": {
          "id": "$licenses[0].id",
          "created": "$licenses[0].created_at",
          "expiry": null
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_SIGN with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-signed-payload-here"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "some-signed-payload-here" using "RSA_2048_PKCS1_SIGN"
    And the response body should be a "license" with the scheme "RSA_2048_PKCS1_SIGN"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0].id",
        "scheme": "RSA_2048_PKCS1_PSS_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_PSS_SIGN" key with the following dataset:
      """
      {
        "account": { "id": "$accounts[0].id" },
        "product": { "id": "$products[0].id" },
        "policy": {
          "id": "$policies[0].id",
          "duration": $policies[0].duration
        },
        "user": null,
        "license": {
          "id": "$licenses[0].id",
          "created": "$licenses[0].created_at",
          "expiry": "$licenses[0].expiry"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-signed-payload-here"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "some-signed-payload-here" using "RSA_2048_PKCS1_PSS_SIGN"
    And the response body should be a "license" with the scheme "RSA_2048_PKCS1_PSS_SIGN"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN with an empty key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": ""
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "cannot be blank",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0].id",
        "scheme": "RSA_2048_JWT_RS256"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_JWT_RS256" key with the following dataset:
      """
      {
        "iss": "https://keygen.sh",
        "aud": "$licenses[0].account_id",
        "sub": "$licenses[0].id",
        "exp": $licenses[0].expiry.to_i,
        "iat": $licenses[0].created_at.to_i,
        "nbf": $licenses[0].created_at.to_i
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 with an invalid payload
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_JWT_RS256"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-non-json-payload"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "key is not a valid JWT claims payload (must be a valid JSON encoded string)",
        "code": "KEY_JWT_CLAIMS_INVALID",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 with an invalid JWT exp
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_JWT_RS256"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{\"exp\":\"foo\"}"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "key is not a valid JWT claims payload (exp claim must be a numeric value but it is a string)",
        "code": "KEY_JWT_CLAIMS_INVALID",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 with a pre-determined key
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
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_JWT_RS256"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{ \"exp\": 4691671952 }"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the JWT key '{ "exp": 4691671952 }' using "RSA_2048_JWT_RS256"
    And the response body should be a "license" with the scheme "RSA_2048_JWT_RS256"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_SIGN_V2 for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0].id",
        "scheme": "RSA_2048_PKCS1_SIGN_V2"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_SIGN_V2" key with the following dataset:
      """
      {
        "account": { "id": "$accounts[0].id" },
        "product": { "id": "$products[0].id" },
        "policy": {
          "id": "$policies[0].id",
          "duration": $policies[0].duration
        },
        "user": {
          "id": "$users[1].id",
          "email": "$users[1].email"
        },
        "license": {
          "id": "$licenses[0].id",
          "created": "$licenses[0].created_at",
          "expiry": "$licenses[0].expiry"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_SIGN_V2 with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_SIGN_V2"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-signed-payload-here"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "some-signed-payload-here" using "RSA_2048_PKCS1_SIGN_V2"
    And the response body should be a "license" with the scheme "RSA_2048_PKCS1_SIGN_V2"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0].id",
        "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_PSS_SIGN_V2" key with the following dataset:
      """
      {
        "account": { "id": "$accounts[0].id" },
        "product": { "id": "$products[0].id" },
        "policy": {
          "id": "$policies[0].id",
          "duration": $policies[0].duration
        },
        "user": null,
        "license": {
          "id": "$licenses[0].id",
          "created": "$licenses[0].created_at",
          "expiry": "$licenses[0].expiry"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-signed-payload-here"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "some-signed-payload-here" using "RSA_2048_PKCS1_PSS_SIGN_V2"
    And the response body should be a "license" with the scheme "RSA_2048_PKCS1_PSS_SIGN_V2"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 with a pre-determined ID and key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "00000000-ceca-491a-9741-fddf0082b567",
          "attributes": {
            "key": "id=00000000-ceca-491a-9741-fddf0082b567"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the id "00000000-ceca-491a-9741-fddf0082b567"
    And the response body should be a "license" with the signed key of "id=00000000-ceca-491a-9741-fddf0082b567" using "RSA_2048_PKCS1_PSS_SIGN_V2"
    And the response body should be a "license" with the scheme "RSA_2048_PKCS1_PSS_SIGN_V2"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 with a pre-determined ID and autogen key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "00000000-ceca-491a-9741-fddf0082b567",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the id "00000000-ceca-491a-9741-fddf0082b567"
    And the response body should be a "license" with the scheme "RSA_2048_PKCS1_PSS_SIGN_V2"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_PSS_SIGN_V2" key with the following dataset:
      """
      {
        "account": { "id": "$accounts[0].id" },
        "product": { "id": "$products[0].id" },
        "policy": {
          "id": "$policies[0].id",
          "duration": $policies[0].duration
        },
        "user": null,
        "license": {
          "id": "00000000-ceca-491a-9741-fddf0082b567",
          "created": "$licenses[0].created_at",
          "expiry": "$licenses[0].expiry"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 with a pre-determined ID that conflicts with another license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2"
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "id": "00000000-ceca-491a-9741-fddf0082b567"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "00000000-ceca-491a-9741-fddf0082b567",
          "attributes": {
            "key": "id=00000000-ceca-491a-9741-fddf0082b567"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 1 "license"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must not conflict with another license",
        "source": {
          "pointer": "/data/id"
        },
        "code": "ID_CONFLICT"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 with a pre-determined ID that is not a UUID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "1",
          "attributes": {
            "key": "id=1"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "type mismatch (received string expected UUID string)",
        "source": {
          "pointer": "/data/id"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ED25519_SIGN for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0].id",
        "scheme": "ED25519_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "ED25519_SIGN" key with the following dataset:
      """
      {
        "account": { "id": "$accounts[0].id" },
        "product": { "id": "$products[0].id" },
        "policy": {
          "id": "$policies[0].id",
          "duration": $policies[0].duration
        },
        "user": null,
        "license": {
          "id": "$licenses[0].id",
          "created": "$licenses[0].created_at",
          "expiry": "$licenses[0].expiry"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ED25519_SIGN with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "ED25519_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "ed25519-signed-payload"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "ed25519-signed-payload" using "ED25519_SIGN"
    And the response body should be a "license" with the scheme "ED25519_SIGN"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ED25519_SIGN with a short key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "ED25519_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "short"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "short" using "ED25519_SIGN"
    And the response body should be a "license" with the scheme "ED25519_SIGN"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ECDSA_P256_SIGN for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0].id", "scheme": "ECDSA_P256_SIGN" }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "ECDSA_P256_SIGN" key with the following dataset:
      """
      {
        "account": { "id": "$accounts[0].id" },
        "product": { "id": "$products[0].id" },
        "policy": {
          "id": "$policies[0].id",
          "duration": $policies[0].duration
        },
        "user": null,
        "license": {
          "id": "$licenses[0].id",
          "created": "$licenses[0].created_at",
          "expiry": "$licenses[0].expiry"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ECDSA_P256_SIGN with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "scheme": "ECDSA_P256_SIGN" }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "ecdsa-signed-payload"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "ecdsa-signed-payload" using "ECDSA_P256_SIGN"
    And the response body should be a "license" with the scheme "ECDSA_P256_SIGN"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ECDSA_P256_SIGN with a short key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "scheme": "ECDSA_P256_SIGN" }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "short"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the signed key of "short" using "ECDSA_P256_SIGN"
    And the response body should be a "license" with the scheme "ECDSA_P256_SIGN"
    And the response body should be a "license" that is not encrypted
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license without a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" that is not protected
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a null user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": null
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license without a policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license with an invalid policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$users[1]"
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
        "detail": "must exist",
        "code": "POLICY_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a reserved key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "actions"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "is reserved",
        "code": "KEY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a license for themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User creates a license for themself (user lacks permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User creates a license for themself (token lacks permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["license.create", "license.validate"] }
      """
    And the current account has 1 "token" for the last "user"
    And the last "token" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates an unprotected license for themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": false
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/protected"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a protected license for themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": true
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/protected"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a license for themself with a pre-determined ID
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "00000000-f0c3-42d0-83bb-2c95df786823",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/id"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a suspended license for themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "suspended": true
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/suspended"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a license for themself with a pre-determined expiry
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2099-09-01T22:53:37.000Z"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/expiry"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create a license without a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create a license for another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using a pooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "usePool": true,
        "strict": true
      }
      """
    And the current account has 4 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 3 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the current account should have 3 "keys"
    And the response body should be a "license" that is strict
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with an empty policy pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "usePool": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "pool is empty",
        "code": "POLICY_POOL_EMPTY",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license for a user of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "TOKEN_INVALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" that is protected
    And the response body should be a "license" that is not strict
    And the response body should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a protected license using a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": true
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" that is protected
    And the response body should be a "license" that is not strict
    And the response body should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a protected license using an unprotected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": false,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": true
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" that is protected
    And the response body should be a "license" that is not strict
    And the response body should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an unprotected license using a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": false
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" that is not protected
    And the response body should be a "license" that is not strict
    And the response body should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates a license using a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "month",
        "checkInIntervalCount": 3,
        "protected": true
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" that is protected
    And the response body should be a "license" that is requireCheckIn
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates a license with a pre-determined ID
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "month",
        "checkInIntervalCount": 3,
        "protected": true
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "00000000-e0e1-4c06-a313-cba8cce6be00",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the id "00000000-e0e1-4c06-a313-cba8cce6be00"
    And the response body should be a "license" that is protected
    And the response body should be a "license" that is requireCheckIn
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Product creates a license with custom permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ce
  Scenario: Product creates a license with custom permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """

  @ee
  Scenario: Product creates a license with custom permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a license with custom permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user license with custom permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["license.validate", "license.read"] }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read",
              "machine.create",
              "machine.delete",
              "machine.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job

  @ee
  Scenario: Product creates a user license with custom permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "user" with the following:
      """
      { "permissions": ["license.validate", "license.read"] }
      """
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "license.validate",
              "license.read",
              "machine.create",
              "machine.delete",
              "machine.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user license with default permissions (without override)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the following attributes:
      """
      {
        "permissions": [
          "arch.read",
          "artifact.read",
          "channel.read",
          "component.create",
          "component.delete",
          "component.read",
          "component.update",
          "constraint.read",
          "engine.read",
          "entitlement.read",
          "group.owners.read",
          "group.read",
          "license.check-in",
          "license.check-out",
          "license.read",
          "license.usage.increment",
          "license.validate",
          "machine.check-out",
          "machine.create",
          "machine.delete",
          "machine.heartbeat.ping",
          "machine.proofs.generate",
          "machine.read",
          "machine.update",
          "package.read",
          "platform.read",
          "process.create",
          "process.delete",
          "process.heartbeat.ping",
          "process.read",
          "process.update",
          "release.download",
          "release.read",
          "release.upgrade",
          "token.read",
          "token.regenerate",
          "token.revoke"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job

  @ee
  Scenario: Product creates a user license with default permissions (with override)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
     And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_license_permissions",
        "value":  [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.read"
        ]
      }
      """
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.read"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job

  @ee
  Scenario: Product creates a license with unsupported permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "product.create"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
          "title": "Unprocessable resource",
          "detail": "unsupported permissions",
          "code": "PERMISSIONS_NOT_ALLOWED",
          "source": {
            "pointer": "/data/attributes/permissions"
          },
          "links": {
            "about": "https://keygen.sh/docs/api/licenses/#licenses-object-attrs-permissions"
          }
        }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a license with unsupported permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "product.create"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
          "title": "Unprocessable resource",
          "detail": "unsupported permissions",
          "code": "PERMISSIONS_NOT_ALLOWED",
          "source": {
            "pointer": "/data/attributes/permissions"
          },
          "links": {
            "about": "https://keygen.sh/docs/api/licenses/#licenses-object-attrs-permissions"
          }
        }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a license with invalid permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "foo.bar"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
          "title": "Unprocessable resource",
          "detail": "unsupported permissions",
          "code": "PERMISSIONS_NOT_ALLOWED",
          "source": {
            "pointer": "/data/attributes/permissions"
          },
          "links": {
            "about": "https://keygen.sh/docs/api/licenses/#licenses-object-attrs-permissions"
          }
        }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a license with invalid permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "foo.bar"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
          "title": "Unprocessable resource",
          "detail": "unsupported permissions",
          "code": "PERMISSIONS_NOT_ALLOWED",
          "source": {
            "pointer": "/data/attributes/permissions"
          },
          "links": {
            "about": "https://keygen.sh/docs/api/licenses/#licenses-object-attrs-permissions"
          }
        }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User creates a license with custom permissions (standard tier)
    Given the current account is "test1"
    And the current account has 1 unprotected "policy"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "account.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User creates a license with custom permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 unprotected "policy"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "permissions": [
              "account.read"
            ]
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: User creates a license with default permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 1 unprotected "policy"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_license_permissions",
        "value": [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.read",
          "user.read"
        ]
      }
      """
    And I am a user of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.read",
          "user.read"
        ]
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  Scenario: User creates a license using an unprotected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "name": "Trial Policy",
        "duration": "$time.30.days",
        "protected": false
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a license using a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "name": "Pro Policy",
        "duration": "$time.1.year",
        "protected": true
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create a license with mismatched policy/user IDs
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$users[1]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin uses an invalid token that looks like a UUID while attempting to create a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I send the following headers:
      """
      {
        "Authorization": "Bearer 852da78f-1444-4462-8863-d7b9fff9e003",
        "Origin": "https://app.keygen.sh"
      }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "Token format is invalid (make sure that you're providing a token value, not a token's UUID identifier)",
        "code": "TOKEN_FORMAT_INVALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin uses an invalid token while attempting to create a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I send the following headers:
      """
      { "Authorization": "Bearer prod-4TzUcN9xMV2cUVT3AuDbPx8XWXnDRF4TzUcN9xMV2cUVT3AuDbPx8XWXnDRFnReibxxgBxXaY2gpb7DRDkUmZpyYi2sXzYfyVL4buWtbgyFD9zbd1319f14b90de1cv2" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "TOKEN_INVALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create a license using an invalid policy ID
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "fb00afb8-38a6-48e5-b22a-b041a4e6d843"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create a license using a policy they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "policies"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create a license for a user of another account
    Given the account "test2" has 2 "users"
    And the second "user" of account "test2" has the following attributes:
      """
      { "id": "cc259aaf-041e-4b91-84f9-92034f5b02d5" }
      """
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "owner": {
              "data": {
                "type": "users",
                "id": "cc259aaf-041e-4b91-84f9-92034f5b02d5"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "OWNER_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/owner"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin sends invalid JSON while attempting to create a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The request could not be completed because it contains invalid JSON (check formatting/encoding)",
        "code": "JSON_INVALID"
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to create a license while on a paid tier with card but has exceeded their max licensed user limit
    Given I am an admin of account "test1"
    And the account "test1" has a max license limit of 50
    And the account "test1" is subscribed
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 50 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 51 "licenses"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license while trialing a paid tier with card but has exceeded their max licensed user limit
    Given I am an admin of account "test1"
    And the account "test1" has a max license limit of 50
    And the account "test1" does have a card on file
    And the account "test1" is trialing
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 50 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 51 "licenses"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license while trialing a paid tier without card but has exceeded their max licensed user limit
    Given I am an admin of account "test1"
    And the account "test1" has a max license limit of 50
    And the account "test1" does not have a card on file
    And the account "test1" is trialing
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 50 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "402"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "Your tier's active licensed user limit of 50 has been reached for your account. Please upgrade to a paid tier and add a payment method at https://app.keygen.sh/billing.",
        "code": "ACCOUNT_ALU_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/relationships/account"
        }
      }
      """
    And the current account should have 50 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a license while on the free tier but has exceeded their max licensed user limit
    Given I am an admin of account "test1"
    And the account "test1" has a max license limit of 50
    And the account "test1" is on a free tier
    And the account "test1" is subscribed
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 50 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "402"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "Your tier's active licensed user limit of 50 has been reached for your account. Please upgrade to a paid tier and add a payment method at https://app.keygen.sh/billing.",
        "code": "ACCOUNT_ALU_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/relationships/account"
        }
      }
      """
    And the current account should have 50 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a license
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "TOKEN_MISSING"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a floating license that overrides its policy's max machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxMachines": 3,
        "floating": true
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxMachines": 9
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxMachines "9"
    And the response body should be a "license" that is floating
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a node-locked license that overrides its policy's max machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxMachines": 1,
        "floating": false
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxMachines": 10
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "code": "MAX_MACHINES_INVALID",
        "detail": "must be equal to 1 for non-floating policy",
        "source": {
          "pointer": "/data/attributes/maxMachines"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a floating license that overrides its policy's max machines (noop)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxMachines": 5,
        "floating": true
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxMachines": null
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxMachines "5"
    And the response body should be a "license" that is floating
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a node-locked license that overrides its policy's max machines (noop)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxMachines": 1,
        "floating": false
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxMachines": null
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxMachines "1"
    And the response body should be a "license" that is not floating
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license that overrides its policy's max cores
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxCores": 8
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxCores": 32
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxCores "32"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license that overrides its policy's max cores (noop)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxCores": 16
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxCores": null
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxCores "16"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a max memory override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxMemory": 131072
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxMemory "131072"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with an invalid max memory override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxMemory": -1
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
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
        "code": "MAX_MEMORY_INVALID",
        "source": {
          "pointer": "/data/attributes/maxMemory"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with a max disk override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxDisk": 4096000
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxDisk "4096000"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with an invalid max disk override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxDisk": -1
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
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
        "code": "MAX_DISK_INVALID",
        "source": {
          "pointer": "/data/attributes/maxDisk"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license that overrides its policy's max uses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxUses": 100
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxUses": 500
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxUses "500"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license that overrides its policy's max uses (noop)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      {
        "maxUses": 100
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxUses": null
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with maxUses "100"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license that overrides its policy's max processes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      { "maxProcesses": 8 }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxProcesses": 32
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following attributes:
      """
      { "maxProcesses": 32 }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license that overrides its policy's max processes (noop)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      { "maxProcesses": 16 }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxProcesses": null
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license" with the following attributes:
      """
      { "maxProcesses": 16 }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a license that overrides the policy's max machines
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 3
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxMachines": 999999999
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/maxMachines"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a license that overrides the policy's max processes
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "maxProcesses": 1 }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxProcesses": 999999999
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the current account should have 0 "licenses"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/maxProcesses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  # Scenario: Admin sends a badly encoded URL query parameter when attempting to create a license
  #   Given I am an admin of account "test1"
  #   And the current account is "test1"
  #   And the current account has 1 "webhook-endpoint"
  #   And the current account has 1 "policies"
  #   And I use an authentication token
  #   When I send a POST request to "/accounts/test1/licenses?meta=%7B+++++%4"
  #   Then the response status should be "400"
  #   And the response body should be an array of 1 error
  #   And the first error should have the following properties:
  #     """
  #     {
  #       "title": "Bad request",
  #       "detail": "The request could not be completed because it contains invalid query parameters (check encoding)",
  #       "code": "PARAMETERS_INVALID"
  #     }
  #     """
  #   And the current account should have 0 "licenses"
  #   And sidekiq should have 0 "webhook" jobs
  #   And sidekiq should have 0 "event-log" jobs
  #   And sidekiq should have 1 "request-log" job

  # Expiration basis
  Scenario: Admin creates a license with a creation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_CREATION",
        "duration": $time.1.year
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have a 1 year expiry

  Scenario: Admin creates a license with a validation expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_VALIDATION",
        "duration": $time.1.year
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should not have an expiry

  Scenario: Admin creates a license with a creation expiration basis (set)
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_CREATION",
        "duration": $time.1.year
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2022-01-03T14:18:02.743Z"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have the expiry "2022-01-03T14:18:02.743Z"

  Scenario: Admin creates a license with a short key
    Given the current account is "test1"
    And the current account has 1 "policy"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "short"
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
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
          "detail": "is too short (minimum is 6 characters)",
          "source": {
            "pointer": "/data/attributes/key"
          },
          "code": "KEY_TOO_SHORT"
        }
      """

  Scenario: Admin creates a license using scheme ED25519_SIGN using template variables
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "ED25519_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{ \"id\": \"{{id}}\", \"issued\": \"{{created}}\", \"expires\": \"{{expiry}}\" }"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "ED25519_SIGN" key with the following dataset:
      """
      {
        "id": "$licenses[0].id",
        "issued": "$licenses[0].created_at",
        "expires": "$licenses[0].expiry"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ECDSA_P256_SIGN using template variables
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "scheme": "ECDSA_P256_SIGN" }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{\"id\":\"{{id}}\",\"alg\":\"nist-p256\",\"iss\":\"{{created}}\",\"exp\":\"{{expiry}}\"}"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "ECDSA_P256_SIGN" key with the following dataset:
      """
      {"id":"$licenses[0].id","alg":"nist-p256","iss":"$licenses[0].created_at","exp":"$licenses[0].expiry"}
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN_V2 using template variables
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2",
        "duration": null
      }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "email": "test@keygen.example" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "75481f3c-bf58-4d3f-8457-eea2b7291f4e",
          "attributes": {
            "key": "{ \"id\": \"{{id}}\", \"email\": \"{{email}}\", \"expiry\": \"{{expiry}}\" }"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the id "75481f3c-bf58-4d3f-8457-eea2b7291f4e"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_PSS_SIGN_V2" key with the following dataset:
      """
      {
        "id": "75481f3c-bf58-4d3f-8457-eea2b7291f4e",
        "email": "test@keygen.example",
        "expiry": ""
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_SIGN_V2 using template variables
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_SIGN_V2",
        "duration": "$time.2.weeks",
        "maxMachines": 3,
        "maxCores": 32
      }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "email": "test@keygen.example" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{
              \"account\": \"{{account}}\",
              \"product\": \"{{product}}\",
              \"policy\": \"{{policy}}\",
              \"user\": \"{{user}}\",
              \"email\": \"{{email}}\",
              \"created\": \"{{created}}\",
              \"expiry\": \"{{expiry}}\",
              \"duration\": \"{{duration}}\",
              \"id\": \"{{id}}\"
            }"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_SIGN_V2" key with the following dataset:
      """
      {
        "account": "$accounts[0].id",
        "product": "$products[0].id",
        "policy": "$policies[0].id",
        "user": "$users[1].id",
        "email": "$users[1].email",
        "created": "$licenses[0].created_at",
        "expiry": "$licenses[0].expiry",
        "duration": "$policies[0].duration",
        "id": "$licenses[0].id"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN using template variables
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN",
        "duration": null,
        "maxMachines": null,
        "maxCores": null
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{
              \"account\": \"{{account}}\",
              \"product\": \"{{product}}\",
              \"policy\": \"{{policy}}\",
              \"user\": \"{{user}}\",
              \"email\": \"{{email}}\",
              \"created\": \"{{created}}\",
              \"expiry\": \"{{expiry}}\",
              \"duration\": \"{{duration}}\",
              \"id\": \"{{id}}\"
            }"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "RSA_2048_PKCS1_PSS_SIGN" key with the following dataset:
      """
      {
        "account": "$accounts[0].id",
        "product": "$products[0].id",
        "policy": "$policies[0].id",
        "user": "",
        "email": "",
        "created": "$licenses[0].created_at",
        "expiry": "",
        "duration": "",
        "id": "$licenses[0].id"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license without a scheme using template variables
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{{account}}-{{product}}-{{id}}"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should be a "license" with the key "{{account}}-{{product}}-{{id}}"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme ED25519_SIGN using invalid template variables
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "ED25519_SIGN"
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "{ \"foo\": \"{{bar}}\", \"baz\": \"{{1}}\", \"qux\": \"{{{{private_key}}}}\" }"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the response body should a "license" that contains a valid "ED25519_SIGN" key with the following dataset:
      """
      { "foo": "", "baz": "", "qux": "{{}}" }
      """
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with nested metadata (default)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "parentKey": {
                "childKey": "value"
              }
            }
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      {
        "metadata": {
          "parentKey": {
            "childKey": "value"
          }
        }
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license with nested metadata (v1.4)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And I use an authentication token
    And I use API version "1.4"
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "parentKey": {
                "childKey": "value"
              }
            }
          },
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      {
        "metadata": {
          "parentKey": {
            "child_key": "value"
          }
        }
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  # product-specific webhook smoke tests
  Scenario: Product creates a license and generates authorized webhooks for its product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "webhook-endpoints" for each "product"
    And the current account has 1 "policy" for each "product"
    And I am the first product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": { "type": "policies", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job
