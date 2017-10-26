@api/v1
Feature: Create license

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
    And sidekiq should have 1 "metric" job

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
            "key": "a"
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
    And the JSON response should be a "license" with the key "a"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

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
        "key": "a"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
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
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a duplicate license of another account with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the account "test2" has 1 "policy"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "key": "a"
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
            "key": "a"
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
    And the JSON response should be a "license" with maxMachines "3"
    And the JSON response should be a "license" with the key "a"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Admin creates an encrypted license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "encrypted": true }
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
    And the JSON response should be a "license" that is encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

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
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

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
    And sidekiq should have 1 "metric" job

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
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates an encrypted license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      { "encrypted": true, "strict": true }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
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
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot specify key for encrypted license",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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
    And sidekiq should have 1 "metric" job

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
    And sidekiq should have 0 "metric" jobs

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
    And sidekiq should have 0 "metric" jobs

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
    And the JSON response should be a "license" that is not floating
    And the JSON response should be a "license" that is strict
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

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
    And the JSON response should be an array of 1 error
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

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
    And I am a product of account "test1"
    And the current product has 1 "policy"
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
    And the JSON response should be a "license" that is requireCheckIn
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: User creates a license using a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
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
    And sidekiq should have 0 "metric" jobs

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
    And sidekiq should have 0 "metric" jobs
