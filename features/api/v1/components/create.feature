@api/v1
Feature: Create machine component
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components"
    Then the response status should be "403"
    And the current account should have 0 "components"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "0af831cd3c2f494aa8311ab13f2b6ec1",
            "name": "CPU"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "component" with the following relationships:
      """
      {
        "machine": {
          "data": {
            "type": "machines",
            "id": "$machines[0]"
          },
          "links": {
            "related": "/v1/accounts/$account/components/$components[0]/machine"
          }
        }
      }
      """
    And the response body should be a "component" with the following attributes:
      """
      {
        "fingerprint": "0af831cd3c2f494aa8311ab13f2b6ec1",
        "name": "CPU"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a component for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "47aac935086a472282ed7218730d8e89",
            "name": "GPU"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Sales creates a component for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "192.168.1.1",
            "name": "IP"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Support attempts to create a component for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "005322acdf11488faa5dc0d69b11e576",
            "name": "MOBO"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Read-only attempts to create a component for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "af:5f:db:75:f4:51:41:b7:bf:1f:77:bd:4a:8f:4d:a0",
            "name": "MAC"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin creates a component with a fingerprint matching another component for a different machine (UNIQUE_PER_MACHINE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_MACHINE" }
      """
    And the current account has 1 "license" for each "policy"
    And the current account has 2 "machines" for each "license"
    And the current account has 1 "component" for the last "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: Admin creates a component with a fingerprint matching another component for the same machine (UNIQUE_PER_MACHINE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_MACHINE" }
      """
    And the current account has 1 "license" for each "policy"
    And the current account has 2 "machines" for each "license"
    And the current account has 1 "component" for the first "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with a fingerprint matching another component for a different license (UNIQUE_PER_LICENSE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_LICENSE" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "machine" for each "license"
    And the current account has 1 "component" for the last "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: Admin creates a component with a fingerprint matching another component for the same license (UNIQUE_PER_LICENSE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_LICENSE" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 2 "machines" for each "license"
    And the current account has 1 "component" for the second "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "has already been taken for this license",
        "code": "FINGERPRINT_TAKEN",
        "source": {
          "pointer": "/data/attributes/fingerprint"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with a fingerprint matching another component for a different policy (UNIQUE_PER_POLICY)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 2 "policies" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_POLICY" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 2 "machines" for each "license"
    And the current account has 1 "component" for the last "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: Admin creates a component with a fingerprint matching another component for the same policy (UNIQUE_PER_POLICY)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 2 "policies" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_POLICY" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 2 "machines" for each "license"
    And the current account has 1 "component" for the third "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with a fingerprint matching another component for a different product (UNIQUE_PER_PRODUCT)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "machine" for each "license"
    And the current account has 1 "component" for the third "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: Admin creates a component with a fingerprint matching another component for the same product (UNIQUE_PER_PRODUCT)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "machine" for each "license"
    And the current account has 1 "component" for the second "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with a fingerprint matching another component (UNIQUE_PER_ACCOUNT)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_ACCOUNT" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "machine" for each "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: Admin creates a component with a fingerprint matching another component for a different product (UNIQUE_PER_ACCOUNT)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_ACCOUNT" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "machine" for each "license"
    And the current account has 1 "component" for the third "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with a fingerprint matching another component for the same product (UNIQUE_PER_ACCOUNT)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "policy" for each "product" with the following:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_ACCOUNT" }
      """
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "machine" for each "license"
    And the current account has 1 "component" for the second "machine" with the following:
      """
      { "fingerprint": "5f28e8a43bcd402082190b48d0048100" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "5f28e8a43bcd402082190b48d0048100",
            "name": "SSD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component for their account with a fingerprint matching a reserved word
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And the current account has 1 "component"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "actions",
            "name": "reserved"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "is reserved",
        "code": "FINGERPRINT_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/fingerprint"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with missing attributes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
          "pointer": "/data/attributes"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with missing fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "name": "test"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
          "pointer": "/data/attributes/fingerprint"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with missing name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "test"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
          "pointer": "/data/attributes/name"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with missing relationships
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "42",
            "name": "life"
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
          "pointer": "/data/relationships"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with missing machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "42",
            "name": "life"
          },
          "relationships": {
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
          "pointer": "/data/relationships/machine"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a component with an invalid machine UUID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "7E038967-9FAA-41C6-B018-539E601A133B",
            "name": "SystemGUID"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "16896379-73ae-4d92-a458-6e7841c9ad08"
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
        "code": "MACHINE_NOT_FOUND",
        "source": {
          "pointer": "/data/relationships/machine"
        }
      }
    """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an isolated component for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
            "name": "HDD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "component" with the following relationships:
      """
      {
        "environment": {
          "data": {
            "type": "environments",
            "id": "$environments[0]"
          },
          "links": {
            "related": "/v1/accounts/$account/environments/$environments[0]"
          }
        }
      }
      """
    And the response body should be a "component" with the following attributes:
      """
      {
        "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
        "name": "HDD"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a component for their machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
            "name": "HDD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "component" with the following attributes:
      """
      {
        "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
        "name": "HDD"
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a component for their machine with a protected policy
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "08:a6:49:ee:2c:fd:48:bd:a0:f4:68:30:fb:47:6b:69",
            "name": "drive"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: User creates a component for an unprotected machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
            "name": "HDD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "component" with the following attributes:
      """
      {
        "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
        "name": "HDD"
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a component for their machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 floating "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
            "name": "HDD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "component" with the following attributes:
      """
      {
        "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
        "name": "HDD"
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a component for a protected machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
            "name": "HDD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "component" with the following attributes:
      """
      {
        "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
        "name": "HDD"
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a component for their machine with a duplicate fingerprint
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And the first "component" has the following attributes:
      """
      { "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "26f93d8e-e7e0-4078-93af-9132886799c5",
            "name": "HDD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
    And the current account should have 1 "component"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a component for their machine with a blank fingerprint
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "",
            "name": "HDD"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "cannot be blank",
        "source": {
          "pointer": "/data/attributes/fingerprint"
        }
      }
      """
    And the current account should have 0 "components"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a component for their machine with a blank name
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "94619120-910b-47aa-9c9c-7cb9474a5a15",
            "name": ""
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "cannot be blank",
        "source": {
          "pointer": "/data/attributes/name"
        }
      }
      """
    And the current account should have 0 "components"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License creates a component for another license's machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "machines"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "23daa04a-badc-4808-ae52-7b1ba987fa90",
            "name": "GPU"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[1]"
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

  Scenario: Product creates a component for another product's machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "89cadd7c-4f50-45b7-8975-30041e403131",
            "name": "GPU"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: User creates a component for another user's machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "01a7c6dc-74af-4445-89a0-d360ad705948",
            "name": "GPU"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: Anonymous attempts to create a component
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "44a03eb5-9b6c-4ddb-8113-9f70d72bd890",
            "name": "chip"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: Admin of another account attempts to create a component
    Given the current account is "test1"
    And the current account has 10 "webhook-endpoints"
    And the current account has 1 "machine"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "fingerprint": "aebbb996-ddf5-43c4-a99d-c1ce1ec445bd",
            "name": "motherboard"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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

  Scenario: License activates a component with a pre-determined ID
    Given the current account is "test1"
    And the current account has 1 "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/components" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "00000000-2521-4033-9f4f-3675387016f7",
          "attributes": {
            "fingerprint": "04745910-2bc4-44f5-b116-6d11e0b73791",
            "name": "network"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
