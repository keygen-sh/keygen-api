@api/v1
Feature: Create license

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin creates a license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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

  Scenario: Admin creates an encrypted license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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
    And sidekiq should have 1 "webhook" job

  Scenario: Admin creates a license without a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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

  Scenario: Admin attempts to create a license without a policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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
    And sidekiq should have 0 "webhook" job

  Scenario: Admin creates a license specifying a key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
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
    Then the response status should be "400"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs

  Scenario: User creates a license for themself
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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

  Scenario: User attempts to create a license without a user
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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

  Scenario: User attempts to create a license for another user
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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

  Scenario: Admin creates a license with the policy license pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "usePool": true
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
    And sidekiq should have 1 "webhook" job

  Scenario: Admin creates a license with an empty policy license pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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

  Scenario: Admin creates a license for a user of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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
    And sidekiq should have 0 "webhook" jobs

  Scenario: Admin creates a license using a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true
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
    And sidekiq should have 1 "webhook" job

  Scenario: Product creates a license using a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
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
    And sidekiq should have 1 "webhook" job

  Scenario: User creates a license using a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
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
