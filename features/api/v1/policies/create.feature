@api/v1
Feature: Create policy

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
    When I send a POST request to "/accounts/test1/policies"
    Then the response status should be "403"

  Scenario: Admin creates a node-locked policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "floating": false,
            "strict": false,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the maxMachines "1"
    And the JSON response should be a "policy" with a nil maxUses
    And the JSON response should be a "policy" that is not strict
    And the JSON response should be a "policy" with a nil scheme
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" that is not floating
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a floating policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "floating": true,
            "strict": false,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the fingerprintUniquenessStrategy "UNIQUE_PER_LICENSE"
    And the JSON response should be a "policy" with the fingerprintMatchingStrategy "MATCH_ANY"
    And the JSON response should be a "policy" with the expirationStrategy "RESTRICT_ACCESS"
    And the JSON response should be a "policy" with the expirationBasis "FROM_CREATION"
    And the JSON response should be a "policy" with the transferStrategy "KEEP_EXPIRY"
    And the JSON response should be a "policy" with the authenticationStrategy "TOKEN"
    And the JSON response should be a "policy" with the heartbeatCullStrategy "DEACTIVATE_DEAD"
    And the JSON response should be a "policy" with the heartbeatResurrectionStrategy "NO_REVIVE"
    And the JSON response should be a "policy" with a nil maxMachines
    And the JSON response should be a "policy" with a nil maxUses
    And the JSON response should be a "policy" that is not strict
    And the JSON response should be a "policy" with a nil scheme
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" that is floating
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a floating policy for their account with a max machines attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT",
            "maxMachines": 3,
            "floating": true,
            "strict": false,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the maxMachines "3"
    And the JSON response should be a "policy" with the fingerprintUniquenessStrategy "UNIQUE_PER_PRODUCT"
    And the JSON response should be a "policy" with a nil maxUses
    And the JSON response should be a "policy" that is not strict
    And the JSON response should be a "policy" with a nil scheme
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" that is floating
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that inherits from a protected account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Actionsack Map Pack",
            "fingerprintMatchingStrategy": "MATCH_ALL",
            "expirationStrategy": "REVOKE_ACCESS",
            "expirationBasis": "FROM_FIRST_VALIDATION",
            "transferStrategy": "RESET_EXPIRY",
            "authenticationStrategy": "LICENSE",
            "heartbeatCullStrategy": "KEEP_DEAD",
            "heartbeatResurrectionStrategy": "5_MINUTE_REVIVE",
            "maxUses": 5
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the name "Actionsack Map Pack"
    And the JSON response should be a "policy" with the fingerprintMatchingStrategy "MATCH_ALL"
    And the JSON response should be a "policy" with the expirationStrategy "REVOKE_ACCESS"
    And the JSON response should be a "policy" with the expirationBasis "FROM_FIRST_VALIDATION"
    And the JSON response should be a "policy" with the transferStrategy "RESET_EXPIRY"
    And the JSON response should be a "policy" with the authenticationStrategy "LICENSE"
    And the JSON response should be a "policy" with the heartbeatCullStrategy "KEEP_DEAD"
    And the JSON response should be a "policy" with the heartbeatResurrectionStrategy "5_MINUTE_REVIVE"
    And the JSON response should be a "policy" with the maxUses "5"
    And the JSON response should be a "policy" that is protected
    And the JSON response should be a "policy" that is concurrent
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has a max uses is less than the max value of a 4 byte integer
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Large Usage Policy",
            "maxUses": 2147483646
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the name "Large Usage Policy"
    And the JSON response should be a "policy" with the maxUses "2147483646"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has a max uses that is the max value of a 4 byte integer
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Larger Usage Policy",
            "maxUses": 2147483647
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the name "Larger Usage Policy"
    And the JSON response should be a "policy" with the maxUses "2147483647"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has a max uses that exceeds the max value of a 4 byte integer
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Largest Usage Policy",
            "maxUses": 2147483648
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "must be less than or equal to 2147483647",
        "code": "MAX_USES_INVALID",
        "source": {
          "pointer": "/data/attributes/maxUses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid fingerprint uniqueness strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Uniqueness Strategy",
            "fingerprintUniquenessStrategy": "MATCH_NONE"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported fingerprint uniqueness strategy",
        "code": "FINGERPRINT_UNIQUENESS_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/fingerprintUniquenessStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid fingerprint matching strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Matching Strategy",
            "fingerprintMatchingStrategy": "MATCH_NONE"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported fingerprint matching strategy",
        "code": "FINGERPRINT_MATCHING_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/fingerprintMatchingStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid expiration strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Expiration Strategy",
            "expirationStrategy": "ALLOW_ACCESS"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported expiration strategy",
        "code": "EXPIRATION_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/expirationStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid expiration basis
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Expiration Basis",
            "expirationBasis": "FROM_FIRST_READ"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported expiration basis",
        "code": "EXPIRATION_BASIS_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/expirationBasis"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid license auth strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Auth Strategy",
            "authenticationStrategy": "API_KEY"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported authentication strategy",
        "code": "AUTHENTICATION_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/authenticationStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid heartbeat cull strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Cull Strategy",
            "heartbeatCullStrategy": "KILL"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported heartbeat cull strategy",
        "code": "HEARTBEAT_CULL_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/heartbeatCullStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid heartbeat resurrection strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Resurrection Strategy",
            "heartbeatResurrectionStrategy": "1_YEAR_REVIVE"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported heartbeat resurrection strategy",
        "code": "HEARTBEAT_RESURRECTION_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/heartbeatResurrectionStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an incompatible heartbeat resurrection strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Resurrection Strategy",
            "heartbeatResurrectionStrategy": "ALWAYS_REVIVE",
            "heartbeatCullStrategy": "DEACTIVATE_DEAD"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "incompatible heartbeat cull strategy (must be KEEP_DEAD when resurrection strategy is ALWAYS_REVIVE)",
        "code": "HEARTBEAT_CULL_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/heartbeatCullStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid transfer strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Transfer Strategy",
            "transferStrategy": "RENEW_EXPIRY"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported transfer strategy",
        "code": "TRANSFER_STRATEGY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/transferStrategy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has a custom heartbeat duration
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Long Heartbeat Policy",
            "heartbeatDuration": 604800
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the name "Long Heartbeat Policy"
    And the JSON response should be a "policy" with the heartbeatDuration "604800"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that does not have a custom heartbeat duration
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Normal Heartbeat Policy"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the name "Normal Heartbeat Policy"
    And the JSON response should be a "policy" with a nil heartbeatDuration
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy with a custom heartbeat duration that is too short
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Short Heartbeat Policy",
            "heartbeatDuration": 60
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "must be greater than or equal to 120 (2 minutes)",
        "code": "HEARTBEAT_DURATION_INVALID",
        "source": {
          "pointer": "/data/attributes/heartbeatDuration"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has a heartbeat duration that exceeds the max value of a 4 byte integer
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Longer Heartbeat Policy",
            "heartbeatDuration": 2147483648
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "must be less than or equal to 2147483647",
        "code": "HEARTBEAT_DURATION_INVALID",
        "source": {
          "pointer": "/data/attributes/heartbeatDuration"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that inherits from an unprotected account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Actionsack Map Pack 2",
            "concurrent": false
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" that is not protected
    And the JSON response should be a "policy" that is not concurrent
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a protected policy that inherits from an unprotected account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Actionsack Map Pack 2",
            "protected": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" that is protected
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an unprotected policy that inherits from a protected account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Actionsack Map Pack 2",
            "protected": false
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" that is not protected
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an incomplete policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "maxMachines": 5,
            "floating": true,
            "strict": false,
            "scheme": "LEGACY_ENCRYPT",
            "encrypted": true,
            "duration": $time.2.weeks
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create an policy for their account with too short of a duration
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Day Pass",
            "duration": $time.23.hours
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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

  Scenario: Admin attempts to create a policy that is legacy encrypted that uses a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Invalid",
            "scheme": "LEGACY_ENCRYPT",
            "encrypted": true,
            "usePool": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 2 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot be encrypted and use a pool",
        "code": "ENCRYPTED_NOT_SUPPORTED",
        "source": {
          "pointer": "/data/attributes/encrypted"
        }
      }
      """
    And the second error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot use a scheme and use a pool",
        "code": "SCHEME_NOT_SUPPORTED",
        "source": {
          "pointer": "/data/attributes/scheme"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a policy using scheme RSA_2048_PKCS1_ENCRYPT that uses a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Invalid",
            "scheme": "RSA_2048_PKCS1_ENCRYPT",
            "usePool": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "cannot use a scheme and use a pool",
        "code": "SCHEME_NOT_SUPPORTED",
        "source": {
          "pointer": "/data/attributes/scheme"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a policy using scheme RSA_2048_PKCS1_SIGN that uses a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Invalid",
            "scheme": "RSA_2048_PKCS1_SIGN",
            "usePool": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "cannot use a scheme and use a pool",
        "code": "SCHEME_NOT_SUPPORTED",
        "source": {
          "pointer": "/data/attributes/scheme"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a policy using scheme RSA_2048_JWT_RS256 that uses a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Invalid",
            "scheme": "RSA_2048_JWT_RS256",
            "usePool": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "cannot use a scheme and use a pool",
        "code": "SCHEME_NOT_SUPPORTED",
        "source": {
          "pointer": "/data/attributes/scheme"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 7 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Basic",
            "maxMachines": 1,
            "floating": false,
            "strict": true,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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

  Scenario: Product attempts to create a policy for their product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Add-On",
            "maxMachines": 1,
            "floating": false,
            "strict": true,
            "scheme": "LEGACY_ENCRYPT",
            "encrypted": true,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create a policy for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Basic",
            "maxMachines": 1,
            "floating": false,
            "strict": true,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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

  Scenario: Admin creates a policy for their account that requires certain scopes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "requireFingerprintScope": true,
            "requireProductScope": true,
            "requirePolicyScope": true,
            "requireMachineScope": true,
            "requireUserScope": true,
            "duration": null
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" that is requireFingerprintScope
    And the JSON response should be a "policy" that is requireProductScope
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy for their account that requires license check-in
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "requireCheckIn": true,
            "checkInInterval": "month",
            "checkInIntervalCount": 3
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy for their account that requires license check-in that is not valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "requireCheckIn": true,
            "checkInInterval": "millennium",
            "checkInIntervalCount": 0
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "must be one of: day, week, month, year",
        "code": "CHECK_IN_INTERVAL_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/checkInInterval"
        }
      }
      """
    And the second error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a number between 1 and 365 inclusive",
        "code": "CHECK_IN_INTERVAL_COUNT_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/checkInIntervalCount"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy for their account that requires machine heartbeats
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Heartbeat Policy",
            "requireHeartbeat": true,
            "heartbeatCullStrategy": "KEEP_DEAD"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" that does requireHeartbeat
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy for their account that does not require machine heartbeats
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "No Heartbeat Policy",
            "requireHeartbeat": false
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" that does not requireHeartbeat
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a floating policy for their account that is not valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Floating",
            "floating": true,
            "maxMachines": 0
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "must be greater than or equal to 1 for floating policy",
        "code": "MAX_MACHINES_INVALID",
        "source": {
          "pointer": "/data/attributes/maxMachines"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a node-locked policy for their account that is not valid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Node-Locked",
            "floating": false,
            "maxMachines": 5
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "must be equal to 1 for non-floating policy",
        "code": "MAX_MACHINES_INVALID",
        "source": {
          "pointer": "/data/attributes/maxMachines"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an incomplete policy for their account that requires license check-in
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "requireCheckIn": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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

  Scenario: Admin creates a policy using scheme RSA_2048_PKCS1_SIGN for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "RSA Signed",
            "scheme": "RSA_2048_PKCS1_SIGN"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "RSA_2048_PKCS1_SIGN"
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" with the name "RSA Signed"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme RSA_2048_PKCS1_PSS_SIGN for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "RSA Probabilistic Signature Scheme",
            "scheme": "RSA_2048_PKCS1_PSS_SIGN"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "RSA_2048_PKCS1_PSS_SIGN"
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" with the name "RSA Probabilistic Signature Scheme"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme RSA_2048_PKCS1_ENCRYPT for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "RSA Encrypted",
            "scheme": "RSA_2048_PKCS1_ENCRYPT"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "RSA_2048_PKCS1_ENCRYPT"
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" with the name "RSA Encrypted"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme RSA_2048_JWT_RS256 for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "JWT RS256",
            "scheme": "RSA_2048_JWT_RS256"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "RSA_2048_JWT_RS256"
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" with the name "JWT RS256"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme RSA_2048_PKCS1_SIGN_V2 for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "RSA Signed",
            "scheme": "RSA_2048_PKCS1_SIGN_V2"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "RSA_2048_PKCS1_SIGN_V2"
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" with the name "RSA Signed"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme RSA_2048_PKCS1_PSS_SIGN_V2 for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "RSA Probabilistic Signature Scheme",
            "scheme": "RSA_2048_PKCS1_PSS_SIGN_V2"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "RSA_2048_PKCS1_PSS_SIGN_V2"
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" with the name "RSA Probabilistic Signature Scheme"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a legacy encrypted policy using scheme LEGACY_ENCRYPT for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Legacy Encrypted",
            "scheme": "LEGACY_ENCRYPT",
            "encrypted": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "LEGACY_ENCRYPT"
    And the JSON response should be a "policy" that is encrypted
    And the JSON response should be a "policy" with the name "Legacy Encrypted"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme ED25519_SIGN for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Ed25519",
            "scheme": "ED25519_SIGN"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "ED25519_SIGN"
    And the JSON response should be a "policy" that is not encrypted
    And the JSON response should be a "policy" with the name "Ed25519"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a legacy encrypted policy without a scheme for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Legacy Encrypted",
            "encrypted": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "LEGACY_ENCRYPT"
    And the JSON response should be a "policy" that is encrypted
    And the JSON response should be a "policy" with the name "Legacy Encrypted"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme LEGACY_ENCRYPT for their account without encryption
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Legacy Encrypted",
            "scheme": "LEGACY_ENCRYPT"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "must be encrypted when using LEGACY_ENCRYPT scheme",
        "code": "SCHEME_INVALID",
        "source": {
          "pointer": "/data/attributes/scheme"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using an unsupported encryption scheme RSA_2048_PKCS1_SIGN for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Unsupported Encryption Scheme",
            "scheme": "RSA_2048_PKCS1_SIGN",
            "encrypted": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported encryption scheme (scheme must be LEGACY_ENCRYPT for legacy encrypted policies)",
        "code": "SCHEME_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/scheme"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy using scheme AES_SHA256 for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "AES SHA256 Encrypted",
            "scheme": "AES_SHA256"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "detail": "unsupported encryption scheme",
        "source": {
          "pointer": "/data/attributes/scheme"
        },
        "code": "SCHEME_NOT_ALLOWED"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an encrypted policy without a scheme for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Default Scheme",
            "encrypted": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the scheme "LEGACY_ENCRYPT"
    And the JSON response should be a "policy" that is encrypted
    And the JSON response should be a "policy" with the name "Default Scheme"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy for their account that has a duration that is too large
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Duration",
            "duration": 7464960000
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
          "detail": "must be less than or equal to 2147483647",
          "source": {
            "pointer": "/data/attributes/duration"
          },
          "code": "DURATION_INVALID"
        }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has a maximum cores count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Long Heartbeat Policy",
            "maxCores": 32
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be a "policy" with the name "Long Heartbeat Policy"
    And the JSON response should be a "policy" with the maxCores "32"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a policy that has an invalid maximum cores count
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Normal Heartbeat Policy",
            "maxCores": 0
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
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
        "code": "MAX_CORES_INVALID",
        "source": {
          "pointer": "/data/attributes/maxCores"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a policy for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Developer Policy"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Sales creates a policy for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Developer Policy"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Support attempts to create a policy for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Policy"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Read-only attempts to create a policy for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Bad Policy"
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
