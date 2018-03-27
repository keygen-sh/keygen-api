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

  Scenario: Admin creates a policy for their account
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
    And the JSON response should be a "policy" with a nil maxMachines
    And the JSON response should be a "policy" with a nil maxUses
    And the JSON response should be a "policy" that is not strict
    And the JSON response should be a "policy" that is encrypted
    And the JSON response should be a "policy" that is floating
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

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
    And the JSON response should be a "policy" with the maxUses "5"
    And the JSON response should be a "policy" that is protected
    And the JSON response should be a "policy" that is concurrent
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

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
            "encrypted": true,
            "duration": $time.2.weeks
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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

  Scenario: Admin attempts to create a policy that is encrypted and uses a pool
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
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot be encrypted and use a pool",
        "source": {
          "pointer": "/data/attributes/encrypted"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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
            "requireProductScope": true
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
