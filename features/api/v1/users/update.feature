@api/v1
Feature: Update user
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

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0"
    Then the response status should not be "403"

  Scenario: Admin updates themself
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$current" with the following:
      """
      {
        "data": {
          "type": "users",
          "id": "$users[0].id",
          "attributes": {
            "firstName": "Elliot"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the firstName "Elliot"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a user for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 2 "webhook-endpoints"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr. Robot"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the firstName "Mr. Robot"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a user for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr. Robot"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Sales updates a user for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr. Robot"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Support updates a user for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr. Robot"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Read-only updates a user for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr. Robot"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin attempts to update a user for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "lastName": "Updated name"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin promotes a user to admin for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the role "admin"
    And the account "test1" should have 2 "admins"
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin promotes a user to developer for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "developer"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the role "developer"
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin promotes a user to sales for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "sales-agent"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the role "sales-agent"
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin promotes a user to support for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "support-agent"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the role "support-agent"
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin sets a user to read-only for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "read-only"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the role "read-only"
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin promotes a user with an invalid role name for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "mod"
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
        "detail": "is invalid",
        "source": {
          "pointer": "/data/attributes/role"
        }
      }
      """
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin promotes a user to a product role for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "product"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to escalate their privileges to an admin role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to a developer role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "developer"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 0 "developers"
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to a sales agent role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "sales-agent"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 0 "sales-agent"
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to a support agent role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "support-agent"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 0 "support-agent"
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to a read only role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "read-only"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 0 "read-only"
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to a product role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "product"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 0 "products"
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to a license role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "license"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 0 "licenses"
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to an unknown role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "unknown"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to an empty role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": ""
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 1 "admin"

  Scenario: User attempts to escalate their privileges to a nil role
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": null
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
    And the account "test1" should have 1 "admin"

  Scenario: Admin attempts to demote another admin to user
    Given the current account is "test1"
    And the current account has 2 "admins"
    And the current account has 3 "tokens" for each "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "user"
          }
        }
      }
      """
    Then the response status should be "200"
    And the last "user" should have 0 "tokens"

  Scenario: Admin attempts to demote themself to user when they're not the only admin for the account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "admin"
    And the current account has 3 "tokens" for the last "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "user"
          }
        }
      }
      """
    Then the response status should be "200"
    And the current user should have 1 "token"

  Scenario: Admin attempts to demote themself to user when they're the only admin for the account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "user"
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "account must have at least 1 admin user",
        "source": {
          "pointer": "/data/relationships/account"
        },
        "code": "ACCOUNT_ADMINS_REQUIRED"
      }
      """
    And the current user should have 1 "token"

  @ee
  Scenario: Admin attempts to demote themself to user when they're not the only admin for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "admins"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "user"
          }
        }
      }
      """
    Then the response status should be "200"

  @ee
  Scenario: Admin attempts to demote themself to user when they're the only admin for an isolated environment
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am the last admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "user"
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "environment must have at least 1 admin user",
        "source": {
          "pointer": "/data/relationships/environment"
        },
        "code": "ENVIRONMENT_ADMINS_REQUIRED"
      }
      """
    And the current user should have 1 "token"

  @ee
  Scenario: Admin attempts to demote themself to user when they're not the only admin for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "admins"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1?environment=shared" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "user"
          }
        }
      }
      """
    Then the response status should be "200"

  @ee
  Scenario: Admin attempts to demote themself to user when they're the only admin for a shared environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1?environment=shared" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "user"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Admin updates a users metadata
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "customerId": "cust_gV4dW9jrc"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following "metadata":
      """
      { "customerId": "cust_gV4dW9jrc" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a users metadata with a nested hash
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "object": { "key": "value" }
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following "metadata":
      """
      {
        "object": { "key": "value" }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a users metadata with a nested hash of non-scalar values (hash)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "object": {
                "object": { "key": "value" }
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
        "detail": "type mismatch (received object expected metadata object)",
        "source": {
          "pointer": "/data/attributes/metadata"
        }
      }
      """

  Scenario: Admin updates a users metadata with a nested hash of non-scalar values (array)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "array": [
                "foo",
                "bar",
                { "key": "value" },
                "baz"
              ]
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
        "detail": "type mismatch (received object expected metadata object)",
        "source": {
          "pointer": "/data/attributes/metadata"
        }
      }
      """

  Scenario: Admin updates a users metadata with 64 keys
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "key1": 1,
              "key2": 2,
              "key3": 3,
              "key4": 4,
              "key5": 5,
              "key6": 6,
              "key7": 7,
              "key8": 8,
              "key9": 9,
              "key10": 10,
              "key11": 11,
              "key12": 12,
              "key13": 13,
              "key14": 14,
              "key15": 15,
              "key16": 16,
              "key17": 17,
              "key18": 18,
              "key19": 19,
              "key20": 20,
              "key21": 21,
              "key22": 22,
              "key23": 23,
              "key24": 24,
              "key25": 25,
              "key26": 26,
              "key27": 27,
              "key28": 28,
              "key29": 29,
              "key30": 30,
              "key31": 31,
              "key32": 32,
              "key33": 33,
              "key34": 34,
              "key35": 35,
              "key36": 36,
              "key37": 37,
              "key38": 38,
              "key39": 39,
              "key40": 40,
              "key41": 41,
              "key42": 42,
              "key43": 43,
              "key44": 44,
              "key45": 45,
              "key46": 46,
              "key47": 47,
              "key48": 48,
              "key49": 49,
              "key50": 50,
              "key51": 51,
              "key52": 52,
              "key53": 53,
              "key54": 54,
              "key55": 55,
              "key56": 56,
              "key57": 57,
              "key58": 58,
              "key59": 59,
              "key60": 60,
              "key61": 61,
              "key62": 62,
              "key63": 63,
              "key64": 64
            }
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Admin updates a users metadata with too many keys
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "key1": 1,
              "key2": 2,
              "key3": 3,
              "key4": 4,
              "key5": 5,
              "key6": 6,
              "key7": 7,
              "key8": 8,
              "key9": 9,
              "key10": 10,
              "key11": 11,
              "key12": 12,
              "key13": 13,
              "key14": 14,
              "key15": 15,
              "key16": 16,
              "key17": 17,
              "key18": 18,
              "key19": 19,
              "key20": 20,
              "key21": 21,
              "key22": 22,
              "key23": 23,
              "key24": 24,
              "key25": 25,
              "key26": 26,
              "key27": 27,
              "key28": 28,
              "key29": 29,
              "key30": 30,
              "key31": 31,
              "key32": 32,
              "key33": 33,
              "key34": 34,
              "key35": 35,
              "key36": 36,
              "key37": 37,
              "key38": 38,
              "key39": 39,
              "key40": 40,
              "key41": 41,
              "key42": 42,
              "key43": 43,
              "key44": 44,
              "key45": 45,
              "key46": 46,
              "key47": 47,
              "key48": 48,
              "key49": 49,
              "key50": 50,
              "key51": 51,
              "key52": 52,
              "key53": 53,
              "key54": 54,
              "key55": 55,
              "key56": 56,
              "key57": 57,
              "key58": 58,
              "key59": 59,
              "key60": 60,
              "key61": 61,
              "key62": 62,
              "key63": 63,
              "key64": 64,
              "key65": 65
            }
          }
        }
      }
      """
    Then the response status should be "422"

  @ce
  Scenario: Admin updates a user's permissions (standard tier, CE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.validate"]
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
  Scenario: Admin updates a user's permissions (ent tier, CE)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.validate"]
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
  Scenario: Admin updates a user's permissions (standard tier, EE)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.validate"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["license.validate"],
        "role": "user"
      }
      """

  @ee
  Scenario: Admin updates a user's permissions (ent tier, EE)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.validate"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["license.validate"],
        "role": "user"
      }
      """

  @ee
  Scenario: Admin zeroes a user's permissions (standard tier)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": []
          }
        }
      }
      """
     Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": [],
        "role": "user"
      }
      """

  @ee
  Scenario: Admin zeroes a user's permissions (ent tier)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": []
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": [],
        "role": "user"
      }
      """

  @ee
  Scenario: Admin updates an admin's permissions (ent tier)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "admins"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["license.read", "machine.read"],
        "role": "admin"
      }
      """

  @ee
  Scenario: Admin updates an admin's permissions (has admin.* permissions)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "admins"
    And the first "admin" has the following permissions:
      """
      ["admin.update", "admin.read", "user.update", "user.read", "license.read", "license.validate", "machine.read"]
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["license.read", "machine.read"],
        "role": "admin"
      }
      """

  @ee
  Scenario: Admin updates an admin's permissions (no admin.* permissions)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "admins"
    And the first "admin" has the following permissions:
      """
      ["user.update", "user.read", "license.read", "license.validate", "machine.read"]
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
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

  @ee
  Scenario: Admin updates their permissions (no other admins)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "account must have at least 1 admin user with a full permission set",
        "source": {
          "pointer": "/data/relationships/account"
        },
        "code": "ACCOUNT_ADMINS_REQUIRED"
      }
      """

  @ee
  Scenario: Admin updates their permissions (other admins without full permissions)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 1 "admin"
    And the last "admin" has the following permissions:
      """
      ["user.read", "license.read", "machine.read"]
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "account must have at least 1 admin user with a full permission set",
        "source": {
          "pointer": "/data/relationships/account"
        },
        "code": "ACCOUNT_ADMINS_REQUIRED"
      }
      """

  @ee
  Scenario: Admin updates their permissions (isolated environment, other admins without full permissions)
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "admins" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I am the second admin of account "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1?environment=isolated" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "environment must have at least 1 admin user with a full permission set",
        "source": {
          "pointer": "/data/relationships/environment"
        },
        "code": "ENVIRONMENT_ADMINS_REQUIRED"
      }
      """

  @ee
  Scenario: Admin updates their permissions (shared environment, other admins without full permissions)
    Given the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 2 shared "admins" with the following:
      """
      { "permissions": ["license.validate"] }
      """
    And I am the second admin of account "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1?environment=shared" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
          }
        }
      }
      """
    Then the response status should be "200"

  @ee
  Scenario: Admin updates their permissions (other admins with full permissions)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 2 "admins"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["license.read", "machine.read"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["license.read", "machine.read"],
        "role": "admin"
      }
      """

  @ee
  Scenario: Admin updates their permissions (wildcard)
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["*"]
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following attributes:
      """
      {
        "permissions": ["*"],
        "role": "admin"
      }
      """

  @ee
  Scenario: Admin with limited permissions escalates their permissions
    Given the current account is "ent1"
    And the current account has 2 "admins"
    And the first "admin" has the following permissions:
      """
      ["admin.read", "admin.update", "user.create", "user.update"]
      """
    Given I am the first admin of account "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": [
              "admin.create",
              "admin.read",
              "admin.update",
              "admin.delete"
            ]
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
        "detail": "You do not have permission to complete the request (admin lacks privileges to perform action on user)"
      }
      """

  @ee
  Scenario: Admin with limited permissions escalates another admin's permissions
    Given the current account is "ent1"
    And the current account has 2 "admins"
    And the first "admin" has the following permissions:
      """
      ["admin.read", "admin.update", "user.create", "user.update"]
      """
    Given I am the first admin of account "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": [
              "admin.create",
              "admin.read",
              "admin.update",
              "admin.delete"
            ]
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
        "detail": "You do not have permission to complete the request (admin lacks privileges to perform action on user)"
      }
      """

  @ee
  Scenario: Product removes an admin's permissions
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "admin"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$0" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": []
          }
        }
      }
      """
    Then the response status should be "404"

  @ee
  Scenario: Product escalates a user's permissions
    Given the current account is "ent1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "ent1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/ent1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "permissions": ["admin.create"]
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

  @ee
  Scenario: Product updates a users metadata
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "customerId": "cust_gV4dW9jrc"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the following "metadata":
      """
      { "customerId": "cust_gV4dW9jrc" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product promotes a user's role to admin
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates their metadata
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "metadata": {
              "customerId": "cust_gV4dW9jrc"
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Product updates an isolated user
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "user"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Isolated Robot"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the firstName "Isolated Robot"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates a user for their product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr. Robot"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the firstName "Mr. Robot"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a user for another product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "user"
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Mr. Robot"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "user" with the firstName "Mr. Robot"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update an associated user
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "users"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the first "user"
    And the current account has 1 "license-user" for the last "license" and the second "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "firstName": "Jason",
            "lastName": "Bourne"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update their password directly
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$current" with the following:
      """
      {
        "data": {
        "type": "users",
          "attributes": {
            "password": "1n53cur3!"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update another user's password
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "users"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "password": "h4ck3d!"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update a user's password
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "password": "new-password"
          }
        }
      }
      """
    Then the response status should be "200"
    And the third "user" should not have the following attributes:
      """
      { "passwordDigest": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to remove a user's password
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "password": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the third "user" should have the following attributes:
      """
      { "passwordDigest": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a user's password
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 2 "users"
    When I send a PATCH request to "/accounts/test1/users/$2" with the following:
      """
      {
        "data": {
          "type": "users",
          "attributes": {
            "password": "new-password"
          }
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
