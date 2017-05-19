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
    And the JSON response should be a "key" with the key "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

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

  Scenario: Admin creates a key but a license for another already exists with the same key
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
    And sidekiq should have 1 "metric" jobs

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
    And the JSON response should be a "key" with the key "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

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
