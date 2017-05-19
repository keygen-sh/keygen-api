@api/v1
Feature: Update user

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
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
    And the JSON response should be a "user" with the firstName "Elliot"
    And sidekiq should have 1 "metric" job

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
    And the JSON response should be a "user" with the firstName "Mr. Robot"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin updates a user for their account including the wrong id
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
          "id": "foo",
          "attributes": {
            "firstName": "Foobar"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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
    And the JSON response should be a "user"
    And the account "test1" should have 2 "admins"
    And sidekiq should have 1 "metric" job

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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

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

  Scenario: User updates attempts to promote themself to admin
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
    And the account "test1" should have 1 "admin"

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
    And the JSON response should be a "user" with the following "metadata":
      """
      { "customerId": "cust_gV4dW9jrc" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

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
              "nested": { "meta": "data" }
            }
          }
        }
      }
      """
    Then the response status should be "400"

  Scenario: Product updates a users metadata
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And the current product has 1 "user"
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
    And the JSON response should be a "user" with the following "metadata":
      """
      { "customerId": "cust_gV4dW9jrc" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Product promotes a user's role to admin
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a product of account "test1"
    And the current product has 1 "user"
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

  Scenario: Product updates a user for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current product has 1 "user"
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
    And the JSON response should be a "user" with the firstName "Mr. Robot"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

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
    And the JSON response should be a "user" with the firstName "Mr. Robot"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: User attempts to update their password
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
           "password": "new-password"
         }
       }
     }
     """
   Then the response status should be "400"
   And sidekiq should have 0 "webhook" jobs
   And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to update a users password
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
            "password": "h4ck3d!"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
