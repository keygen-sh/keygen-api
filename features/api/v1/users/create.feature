@api/v1
Feature: Create user
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
    When I send a POST request to "/accounts/test1/users"
    Then the response status should be "403"

  Scenario: Anonymous creates a user for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["user.created", "user.updated"]
      }
      """
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "kent <3 lois"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the firstName "Clark"
    And the response body should be a "user" with the role "user"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "users"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous creates a user with role
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.created", "user.updated"] }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "loislane",
            "role": "user"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous creates a user with blank names
    Given the current account is "test1"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "",
            "lastName": "",
            "email": "test@keygen.example",
            "password": "foobarbazqux"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the firstName ""
    And the response body should be a "user" with the lastName ""
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous creates a user with null names
    Given the current account is "test1"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": null,
            "lastName": null,
            "email": "test@keygen.example",
            "password": "foobarbazqux"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with a nil firstName
    And the response body should be a "user" with a nil lastName
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin creates a user for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "isolated@keygen.example"
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin creates a user for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "shared@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin creates a user for an isolated environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "isolated@keygen.example"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the following relationships:
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
    And the current account should have 1 "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin creates a user for a shared environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "shared@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[1]" }
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
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Isolated admin creates a user for the global environment
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "global@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": null
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
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin creates a user for a shared environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "shared@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the following relationships:
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
    And the current account should have 1 "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin creates a user for an isolated environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "isolated@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[1]" }
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
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Shared admin creates a user for the global environment
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "global@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": null
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
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin creates a user for the global environment
    Given the current account is "ent1"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 global "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "global@keygen.example"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the following relationships:
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
    And the current account should have 1 "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin creates a user for an isolated environment
    Given the current account is "ent1"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "isolated@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
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
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Global admin creates a user for a shared environment
    Given the current account is "ent1"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 global "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "shared@keygen.example"
          },
          "relationships": {
            "environment": {
              "data": { "type": "environments", "id": "$environments[0]" }
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
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Anonymous creates a user with permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.created", "user.updated"] }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "loislane",
            "permissions": ["*"]
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
    And the response should contain a valid signature header for "test1"
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Anonymous creates a user with permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.created", "user.updated"] }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "loislane",
            "permissions": ["*"]
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
    And the response should contain a valid signature header for "ent1"
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous creates a user with permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.created", "user.updated"] }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "loislane",
            "permissions": ["*"]
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
    And the response should contain a valid signature header for "test1"
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous creates a user with permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.created", "user.updated"] }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "loislane",
            "permissions": ["*"]
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
    And the response should contain a valid signature header for "ent1"
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous creates a grouped user for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.updated"] }
      """
    And the current account has 1 "group"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "group@keygen.example"
          },
          "relationships": {
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
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
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates a grouped user for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "group"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "group@keygen.example"
          },
          "relationships": {
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the email "group@keygen.example"
    And the response body should be a "user" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped user for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.updated"] }
      """
    And the current account has 1 "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "group@keygen.example"
          },
          "relationships": {
            "group": {
              "data": { "type": "groups", "id": "$groups[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the email "group@keygen.example"
    And the response body should be a "user" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]/group" },
          "data": { "type": "groups", "id": "$groups[0]" }
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped user for an account (null group)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "subscriptions": ["user.created"] }
      """
    And the current account has 1 "group"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "group@keygen.example"
          },
          "relationships": {
            "group": {
              "data": null
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the email "group@keygen.example"
    And the response body should be a "user" with the following relationships:
      """
      {
        "group": {
          "links": { "related": "/v1/accounts/$account/users/$users[1]/group" },
          "data": null
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped user for an account (invalid group)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "group@keygen.example"
          },
          "relationships": {
            "group": {
              "data": { "type": "groups", "id": "a7225f5d-2a2d-4611-b73d-cde8e83b0f5a" }
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
    And the current account should have 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a grouped user for an account (limit exceeded)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "group"
    And the last "group" has the following attributes:
      """
      { "maxUsers": 1 }
      """
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "group@keygen.example"
          },
          "relationships": {
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
        "detail": "user count has exceeded maximum allowed by current group (1)",
        "code": "GROUP_USER_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/relationships/group"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous creates a user with a short password
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "invalid@keygen.example",
            "password": "short"
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
          "code": "PASSWORD_TOO_SHORT",
          "source": {
            "pointer": "/data/attributes/password"
          }
        }
      """

  Scenario: Anonymous creates a user without a password
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "invite@keygen.example",
            "password": null
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the following attributes:
      """
      { "email": "invite@keygen.example" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous creates a user with no name
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["user.created", "user.updated"]
      }
      """
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "cap@keygen.sh",
            "password": "america!"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with a nil firstName
    And the response body should be a "user" with a nil lastName
    And the response body should be a "user" with the role "user"
    And the response should contain a valid signature header for "test1"
    And the current account should have 2 "users"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user for a protected account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "superman+lois"
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create an incomplete user for an account
    Given the current account is "test1"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent"
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error

  Scenario: Anonymous attempts to create a user with invalid parameter types
    Given the current account is "test1"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": 42,
            "password": "superman+lois"
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error

  Scenario: Anonymous attempts to create a user with an invalid email
    Given the current account is "test1"
    And the current account has 1 "user"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "foo.com",
            "password": "superman <3 lois"
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
        "detail": "is invalid",
        "code": "EMAIL_INVALID",
        "source": {
          "pointer": "/data/attributes/email"
        }
      }
      """

  Scenario: Admin creates a user for their protected account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": []
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "!jarvis!"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "user"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer creates a user for their protected account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "!jarvis!"
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Sales creates a user for their protected account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "((jarvis))"
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Support creates a user for their account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "secret123"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Read-only creates a user for their account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "secret123"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin creates an admin for their account (default permissions)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And all "webhook-endpoints" have the following attributes:
      """
      { "subscriptions": ["user.created"] }
      """
    And the current account has 2 "admins"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "ironman@keygen.sh",
            "password": "secret123",
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "admin"
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an admin for their account (has permissions)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And all "webhook-endpoints" have the following attributes:
      """
      { "subscriptions": ["user.created"] }
      """
    And the current account has 2 "admins"
    And the first "admin" has the following permissions:
      """
      ["admin.create", "user.create"]
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "ironman@keygen.sh",
            "password": "secret123",
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "admin"
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an admin for their account (no permissions)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And all "webhook-endpoints" have the following attributes:
      """
      { "subscriptions": ["user.created"] }
      """
    And the current account has 2 "admins"
    And the first "admin" has the following permissions:
      """
      ["user.create"]
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "ironman@keygen.sh",
            "password": "secret123",
            "role": "admin"
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
        "detail": "You do not have permission to complete the request (admin lacks permission to perform action)"
      }
      """

  Scenario: Admin creates a developer for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And all "webhook-endpoints" have the following attributes:
      """
      {
        "subscriptions": ["user.created"]
      }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr.",
            "lastName": "Robot",
            "email": "mr.robot@keygen.sh",
            "password": "l337h4x0r",
            "role": "developer"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "developer"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a sales agent for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And all "webhook-endpoints" have the following attributes:
      """
      {
        "subscriptions": ["user.created"]
      }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Jim",
            "lastName": "Halpert",
            "email": "jim@keygen.sh",
            "password": "bears beets battlestar galactica",
            "role": "sales-agent"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "sales-agent"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a support agent for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And all "webhook-endpoints" have the following attributes:
      """
      {
        "subscriptions": ["user.created"]
      }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Pam",
            "lastName": "Beesly",
            "email": "beesly@keygen.sh",
            "password": "jimjimjimjim",
            "role": "support-agent"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "support-agent"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a read-only for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And all "webhook-endpoints" have the following attributes:
      """
      { "subscriptions": ["user.created"] }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Toby",
            "lastName": "Flenderson",
            "email": "toby@keygen.sh",
            "password": "ScrantonStrangler",
            "role": "read-only"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "read-only"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer attempts to create an admin for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr.",
            "lastName": "Robot",
            "email": "ecorp@keygen.sh",
            "password": "password",
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "400"

  Scenario: Sales attempts to create an admin for their unprotected account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "((jarvis))",
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "400"

  Scenario: Admin attempts to create a user with an invalid role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And the current account has 3 "webhook-endpoints"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Spiderman",
            "lastName": "Parker",
            "email": "spiderman@keygen.sh",
            "password": "i shoot webs",
            "role": "spider"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Admin attempts to create another admin with custom permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Spiderman",
            "lastName": "Parker",
            "email": "spiderman@keygen.sh",
            "password": "webmaster",
            "role": "admin",
            "permissions": [
              "product.create",
              "policy.create"
            ]
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

  @ce
  Scenario: Admin attempts to create another admin with custom permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Spiderman",
            "lastName": "Parker",
            "email": "spiderman@keygen.sh",
            "password": "webmaster",
            "role": "admin",
            "permissions": [
              "product.create",
              "policy.create"
            ]
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

  @ee
  Scenario: Admin attempts to create another admin with custom permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Spiderman",
            "lastName": "Parker",
            "email": "spiderman@keygen.sh",
            "password": "webmaster",
            "role": "admin",
            "permissions": [
              "product.create",
              "policy.create"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["policy.create", "product.create"]
      }
      """
    And the current account should have 2 "admins"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin attempts to create another admin with custom permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Spiderman",
            "lastName": "Parker",
            "email": "spiderman@keygen.sh",
            "password": "webmaster",
            "role": "admin",
            "permissions": [
              "product.create",
              "policy.create"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["policy.create", "product.create"]
      }
      """
    And the current account should have 2 "admins"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an isolated admin for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Ironman",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "my suit's cool",
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a shared user for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "test@keygen.example"
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the role "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates an admin for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Ironman",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "my suit's cool",
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates a user for a protected account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "webhook-endpoints"
    And all "webhook-endpoints" have the following attributes:
      """
      {
        "subscriptions": ["license.created"]
      }
      """
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Ironman",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "jarvis!!"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Product creates a user with custom permissions (standard tier, CE)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Ironman",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "jarvis!!",
            "permissions": [
              "license.validate",
              "license.read"
            ]
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

  @ce
  Scenario: Product creates a user with custom permissions (ent tier, CE)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Ironman",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "jarvis!!",
            "permissions": [
              "license.validate",
              "license.read"
            ]
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

  @ee
  Scenario: Product creates a user with custom permissions (standard tier, EE)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Ironman",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "jarvis!!",
            "permissions": [
              "license.validate",
              "license.read"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "user"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate"
        ]
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with custom permissions (ent tier, EE)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Ironman",
            "lastName": "Stark",
            "email": "ironman@keygen.sh",
            "password": "jarvis!!",
            "permissions": [
              "license.validate",
              "license.read"
            ]
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "user"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate"
        ]
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with default permissions (without override)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "mark.s@lumon.example"
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "user"
    And the response body should be a "user" with the following attributes:
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
          "group.licenses.read",
          "group.machines.read",
          "group.owners.read",
          "group.read",
          "group.users.read",
          "license.check-in",
          "license.check-out",
          "license.create",
          "license.delete",
          "license.policy.update",
          "license.read",
          "license.renew",
          "license.revoke",
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
          "token.generate",
          "token.read",
          "token.regenerate",
          "token.revoke",
          "user.password.reset",
          "user.password.update",
          "user.read",
          "user.second-factors.create",
          "user.second-factors.delete",
          "user.second-factors.read",
          "user.second-factors.update",
          "user.update"
        ]
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with default permissions (with override)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_user_permissions",
        "value":  [
          "license.read",
          "license.validate",
          "user.read"
        ]
      }
      """
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "mark.s@lumon.example"
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "user"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate",
          "user.read"
        ]
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with unsupported permissions (standard tier)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "tony@stark.industries",
            "password": "pepperpots",
            "permissions": [
              "product.create"
            ]
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
          "about": "https://keygen.sh/docs/api/users/#users-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with unsupported permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "tony@stark.industries",
            "password": "pepperpots",
            "permissions": [
              "product.create"
            ]
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
          "about": "https://keygen.sh/docs/api/users/#users-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with invalid permissions (standard tier)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "tony@stark.industries",
            "password": "pepperpots",
            "permissions": [
              "foo.bar"
            ]
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
          "about": "https://keygen.sh/docs/api/users/#users-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with invalid permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "tony@stark.industries",
            "password": "pepperpots",
            "permissions": [
              "foo.bar"
            ]
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
          "about": "https://keygen.sh/docs/api/users/#users-object-attrs-permissions"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with no permissions (standard tier)
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "tony@stark.industries",
            "password": "pepperpots",
            "permissions": []
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "user"
    And the response body should be a "user" with the following attributes:
      """
      { "permissions": [] }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product creates a user with no permissions (ent tier)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Tony",
            "lastName": "Stark",
            "email": "tony@stark.industries",
            "password": "pepperpots",
            "permissions": []
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "user"
    And the response body should be a "user" with the following attributes:
      """
      { "permissions": [] }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create an admin for their account
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Superman",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "sunlight",
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to create a user for a protected account
    Given the current account is "test1"
    And the account "test1" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Clark",
            "lastName": "Kent",
            "email": "superman@keygen.sh",
            "password": "sunlight"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create an admin for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Thor",
            "lastName": "Thor",
            "email": "thor@keygen.sh",
            "password": "*mjolnir*",
            "role": "admin"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with a developer role for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Thor",
            "lastName": "Thor",
            "email": "thor@keygen.sh",
            "password": "mjolnir?",
            "role": "developer"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with a sales agent role for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Thor",
            "lastName": "Thor",
            "email": "thor@keygen.sh",
            "password": "mjolnir--",
            "role": "sales-agent"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with a support agent role for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Thor",
            "lastName": "Thor",
            "email": "thor@keygen.sh",
            "password": "mjolnir++",
            "role": "support-agent"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with a read-only role for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Thor",
            "lastName": "Thor",
            "email": "thor@keygen.sh",
            "password": "mjolnir++",
            "role": "read-only"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with a license role for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Thor",
            "lastName": "Thor",
            "email": "thor@keygen.sh",
            "password": "hunter1",
            "role": "license"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with a product role for an account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Thor",
            "lastName": "Thor",
            "email": "thor@keygen.sh",
            "password": "hunter1",
            "role": "product"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with an admin role for an account (meme casing)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Bad",
            "lastName": "Actor",
            "email": "hack@keygen.sh",
            "password": "ugotpwnd",
            "RoLe": "admin"
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
          "pointer": "/data/attributes/roLe"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to create a user with an admin role for an account (caps casing)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Bad",
            "lastName": "Actor",
            "email": "hack@keygen.sh",
            "password": "ugotpwnd",
            "ROLE": "admin"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Anonymous creates a user with default permissions (with override)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_user_permissions",
        "value":  [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.read",
          "user.password.reset",
          "user.password.update",
          "user.read",
          "user.update"
        ]
      }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "mark.s@lumon.example"
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "user"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.read",
          "user.password.reset",
          "user.password.update",
          "user.read",
          "user.update"
        ]
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 1 "event-log" job

  @ee
  Scenario: Anonymous creates a user with custom permissions (with override)
    Given the current account is "ent1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "setting" with the following:
      """
      {
        "key": "default_user_permissions",
        "value":  [
          "license.read",
          "license.validate",
          "machine.create",
          "machine.read",
          "user.password.reset",
          "user.password.update",
          "user.read",
          "user.update"
        ]
      }
      """
    When I send a POST request to "/accounts/ent1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "mark.s@lumon.example",
            "permissions": [
              "license.read",
              "license.validate",
              "user.read"
            ]
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "request-log" job
    And sidekiq should have 0 "event-log" jobs

  Scenario: Anonymous attempts to send a request containing an invalid byte sequence (bad UTF-8 encoding)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "String in CP1252 encoding: \xE4\xF6\xFC\xDF",
            "lastName": "Partly valid\xE4 UTF-8 encoding: äöüß",
            "email": "thor@keygen.sh",
            "password": "hunter1",
            "role": "admin"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  # Ref: https://github.com/BishopFox/json-interop-vuln-labs/#attack-techniques
  Scenario: Anonymous attempts to send a request containing a unicode injection (1)
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "role": null,
            "role\ud888": "admin"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous attempts to send a request containing a unicode injection (2)
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "role": null,
            "role\x0d": "admin"
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
          "pointer": "/data/attributes/rolex0d"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to send a request containing a stray backslash injection
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "role": null,
            "ro\le": "admin"
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to send a request containing a stray quotes injection
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "role": null,
            'role': "admin"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous attempts to send a request containing a missing quotes injection
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "role": null,
            role: "admin"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous attempts to send a request containing a comment injection (1)
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "firstName": /*,
            "role": "admin",
            "lastName": */
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous attempts to send a request containing a comment injection (2)
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "firstName": "foo"/*,
            "role": "admin",
            "lastName": "bar"*/
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "user" with the firstName "foo"
    And the response body should be a "user" with a nil lastName
    And the response body should be a "user" with the role "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" jobs
    And sidekiq should have 1 "request-log" jobs

  Scenario: Anonymous attempts to send a request containing a comment injection (3)
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities",
            "role": /*"admin"*/null
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
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to send a request containing trailing garbage
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/users" with the following badly encoded data:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "bishopfox+blog@keygen.example",
            "password": "json-interoperability-vulnerabilities"
          }
        }
      }=
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  # product-specific webhook smoke tests
  Scenario: Anonymous creates a user and generates authorized webhooks for all products
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "webhook-endpoints" for each "product"
    When I send a POST request to "/accounts/test1/users" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "email": "xkcd-936@keygen.example",
            "password": "correcthorsebatterystaple"
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 4 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
