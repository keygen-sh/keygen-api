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
    And the JSON response should be a "user" with the firstName "Mr. Robot"
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
    And sidekiq should have 1 "request-log" job

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
    And the JSON response should be a "user"
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
    And the JSON response should be a "user"
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
    And the JSON response should be a "user"
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
    And the JSON response should be a "user"
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
    And sidekiq should have 0 "webhook" jobs
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

  Scenario: Admin attempts to demote themself to user when they're not the only admin
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "admin"
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

  Scenario: Admin attempts to demote themself to user when they're the only admin
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
              "nested": { "meta": "data" }
            }
          }
        }
      }
      """
    Then the response status should be "400"

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
    And sidekiq should have 1 "request-log" job

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
    And the JSON response should be a "user" with the firstName "Mr. Robot"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
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
   Then the response status should be "400"
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
