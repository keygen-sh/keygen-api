@api/v1
Feature: Create key

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
    When I send a POST request to "/accounts/test1/keys"
    Then the response status should be "403"

  Scenario: Admin creates a key for a pooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
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
    And the response body should be a "key" with the key "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key for an unpooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": false }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key for a non-existent policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
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

  Scenario: Admin creates a duplicate key for a pooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 1 "key"
    And the first "key" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key but a license already exists with the same key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key but a license already exists with an ID matching the key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "$licenses[0]"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key with a reserved key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key but a license for another account already exists with the same key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
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
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key that is a duplicate of a key for another account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the account "test2" has 1 "key"
    And the first "key" of account "test2" has the following attributes:
      """
      {
        "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
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
    And the response body should be a "key" with the key "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key with missing key value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a key with missing policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create a key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "sVbmZKq4not2mCEvjEuMVE4cViCWLi"
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
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Unauthenticated user attempts to create a key
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "fw8vuUbmWtZfrLe7Xgmg8xNVhTEjjK"
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
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin of another account attempts to create a key
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "PmL2UPti9ZeJTs4kZvGnLJcvsndWhw"
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
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to create a key for their environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated+pooled "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/keys" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "iso_PmL2UPti9ZeJTs4kZvGnLJcvsndWhw"
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
    And the response body should be a "key" with the following attributes:
      """
      { "key": "iso_PmL2UPti9ZeJTs4kZvGnLJcvsndWhw" }
      """
    And the response body should be a "key" with the following relationships:
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
