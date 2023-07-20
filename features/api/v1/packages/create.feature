@api/v1
Feature: Create package
  Background:
    Given the following "plan" rows exist:
      | id                                   | name  |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Std 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1 |
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
    When I send a POST request to "/accounts/test1/packages"
    Then the response status should be "403"

  Scenario: Admin creates a package for their account
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Cool Package",
            "key": "cool"
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
    And the response body should be a "package" with the following relationships:
      """
      {
        "product": {
          "links": { "related": "/v1/accounts/$account/products/$products[0]" },
          "data": { "type": "products", "id": "$products[0]" }
        }
      }
      """
    And the response body should be a "package" with the following attributes:
      """
      {
        "name": "Cool Package",
        "key": "cool",
        "engine": null
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a package with the PyPI engine
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "PyPI Package",
            "key": "pypi",
            "engine": "pypi"
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
    And the response body should be a "package" with the following relationships:
      """
      {
        "product": {
          "links": { "related": "/v1/accounts/$account/products/$products[0]" },
          "data": { "type": "products", "id": "$products[0]" }
        }
      }
      """
    And the response body should be a "package" with the following attributes:
      """
      {
        "name": "PyPI Package",
        "key": "pypi",
        "engine": "pypi"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a package with a nil engine
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Null Package",
            "key": "null",
            "engine": null
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
    And the response body should be a "package" with the following relationships:
      """
      {
        "product": {
          "links": { "related": "/v1/accounts/$account/products/$products[0]" },
          "data": { "type": "products", "id": "$products[0]" }
        }
      }
      """
    And the response body should be a "package" with the following attributes:
      """
      {
        "name": "Null Package",
        "key": "null",
        "engine": null
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a package with an invalid engine
    Given the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Invalid Package",
            "key": "invalid",
            "engine": "invalid"
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
    Then the response status should be "400"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is invalid",
        "source": {
          "pointer": "/data/attributes/engine"
        }
      }
      """

  Scenario: Admin attempts to create an incomplete package
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "incomplete"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to create a package for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Hax App",
            "key": "hax"
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

  Scenario: Developer creates a package for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And the current account has 1 "product"
    And I am a developer of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Dev App",
            "key": "dev"
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

  Scenario: Sales attempts to create a package for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And the current account has 1 "product"
    And I am a sales agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Sales App",
            "key": "sales"
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

  Scenario: Support attempts to create a package for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And the current account has 1 "product"
    And I am a support agent of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Support App",
            "key": "support"
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

  Scenario: Read-only attempts to create a package for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And the current account has 1 "product"
    And I am a read only of account "test1"
    And I use an authentication token
    And the current account has 2 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Bad App",
            "key": "bad"
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

  @ee
  Scenario: Environment creates an isolated package
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "product"
    And I am the last environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Isolated Package",
            "key": "isolated"
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
    And the response body should be a "package" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a shared package
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "product"
    And I am the last environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Shared Package",
            "key": "shared"
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
    And the response body should be a "package" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to create a package for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Test Package",
            "key": "test"
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
    And the response body should be a "package" with the following relationships:
      """
      {
        "product": {
          "links": { "related": "/v1/accounts/$account/products/$products[0]" },
          "data": { "type": "products", "id": "$products[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to create a package for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Test Package",
            "key": "test"
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

  Scenario: User attempts to create a package for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Test Package",
            "key": "test"
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

  Scenario: Anonymous attempts to create a package for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    When I send a POST request to "/accounts/test1/packages" with the following:
      """
      {
        "data": {
          "type": "packages",
          "attributes": {
            "name": "Test Package",
            "key": "test"
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
