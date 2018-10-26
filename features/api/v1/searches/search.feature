@skip/bullet
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
    When I send a POST request to "/accounts/test1/search"
    Then the response status should be "403"

  Scenario: Admin performs a search by user type with an empty query
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 15 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {}
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 10 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type with an empty query using pagination
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search?page[size]=5&page[number]=1" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {}
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 5 "users"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/search?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/search?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/search?page[number]=3&page[size]=5"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the role relationship
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "role": "admin"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search with a query that is too small
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "key": "ab"
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "search query for 'key' is too small (minimum 3 characters)",
        "source": {
          "pointer": "/meta/query/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search with a metadata query that is too small
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "metadata": {
              "key": "ab"
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
        "detail": "search query for 'key' is too small (minimum 3 characters)",
        "source": {
          "pointer": "/meta/query/metadata/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by an unsearchable type "accounts"
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "accounts",
          "query": {}
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unsupported search type 'accounts'",
        "source": {
          "pointer": "/meta/type"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by an unsearchable type "tokens"
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "tokens",
          "query": {}
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unsupported search type 'tokens'",
        "source": {
          "pointer": "/meta/type"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by an unknown type
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "unknowns",
          "query": {}
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unsupported search type 'unknowns'",
        "source": {
          "pointer": "/meta/type"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by an unknown attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "foo": "bar"
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unsupported search query 'foo' for resource type 'users'",
        "source": {
          "pointer": "/meta/query/foo"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the first and last name attributes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following attributes:
      """
      {
        "firstName": "John",
        "lastName": "Doe"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "firstName": "John",
            "lastName": "Doe"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the full name attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following attributes:
      """
      {
        "firstName": "John",
        "lastName": "Doe"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "fullName": "John Doe"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the first name attribute that is misspelled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following attributes:
      """
      {
        "firstName": "John"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "firstName": "Jonh"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the last name attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following attributes:
      """
      {
        "firstName": "John",
        "lastName": "Doe"
      }
      """
    And the second "user" has the following attributes:
      """
      {
        "firstName": "Jane",
        "lastName": "Doe"
      }
      """
    And the third "user" has the following attributes:
      """
      {
        "firstName": "Joe",
        "lastName": "Doe"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "lastName": "Doe"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 3 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the email attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "email": "$users[3].email"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the metadata attribute using an exact query
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following metadata:
      """
      {
        "customerId": "abfdcc31-d5dd-4a20-b982-a81b9d89dec6"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "metadata": {
              "customerId": "abfdcc31-d5dd-4a20-b982-a81b9d89dec6"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the metadata attribute using an array of terms
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following metadata:
      """
      {
        "customerId": "abfdcc31-d5dd-4a20-b982-a81b9d89dec6"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "metadata": [
              "abfdcc31-d5dd-4a20-b982-a81b9d89dec6"
            ]
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "search query for 'metadata' must be a hash of key-value search terms",
        "source": {
          "pointer": "/meta/query/metadata"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the metadata attribute using a snakecased metadata key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following metadata:
      """
      {
        "customerId": "abfdcc31-d5dd-4a20-b982-a81b9d89dec6"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "license",
          "query": {
            "metadata": {
              "customer_id": "abfdcc31"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the metadata attribute using a nested query that doesn't match
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following metadata:
      """
      {
        "customerId": "51e9a648-6f25-4d43-a6e6-9673a91e2088"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "metadata": {
              "customerId": "abfdcc31"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by user type on the metadata attribute using a nested query that loosely matches
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following metadata:
      """
      {
        "customerId": "51e9a648-6f25-4d43-a6e6-9673a91e2088",
        "payloadId": "abfdcc31-d5dd-4a20-b982-a81b9d89dec6"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "metadata": {
              "customerId": "abfdcc31-d5dd-4a20-b982-a81b9d89dec6",
              "payloadId": "51e9a648-6f25-4d43-a6e6-9673a91e2088"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the key attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "some-license-key"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "key": "some-license-key"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on a large key attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "T1RjZ09Ua2dNR1VnWVRFZ016RWdNREFnTnpRZ1ltSWdOMlVnWkRnZ1lqY2daRFFnWkRVZ09Ea2daVEFnWXpJZ05UUWdaRGdnWld"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "key": "T1RjZ09U"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type using a partial ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "id": "e1fbdc0e-ff25-490b-a92f-93880a21723b"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "id": "e1fbdc0e"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the key attribute using a partial key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "some-license-key"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "key": "some-license"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to perform a search by license type on the key attribute for another account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test2" has 10 "licenses"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "key": "some-license-key"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "key": "some-license-key"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the name attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "name": "Some Customer Name Here"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "name": "Some Customer Name Here"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the policy relationship by ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "policies"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "policyId": "$policies[1]"
      }
      """
    And the third "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "policy": "$policies[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the policy relationship by name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "name": "Premium #1"
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "name": "Premium #2"
      }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "policyId": "$policies[1]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "policy": "Premium"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the user relationship by ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current user has 7 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "user": "$users[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 7 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by license type on the user relationship by email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current user has 5 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "licenses",
          "query": {
            "user": "$users[0].email"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 5 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by policy type on the product relationship by ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 10 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "policies",
          "query": {
            "product": "$products[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "policy"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by policy type on the product relationship by name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the first "product" has the following attributes:
      """
      {
        "name": "Halo 4"
      }
      """
    And the second "product" has the following attributes:
      """
      {
        "name": "Halo:CE"
      }
      """
    And the current account has 10 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]"
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "productId": "$products[1]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "policies",
          "query": {
            "product": "Halo"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 2 "policies"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by machine type on the license relationship by ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current account has 5 "machines"
    And all "machines" have the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "machines",
          "query": {
            "license": "$licenses[0]"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 5 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by machine type on the fingerprint attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "machines"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "machines",
          "query": {
            "fingerprint": "$machines[0].fingerprint"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by machine type on the user relationship by email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]"
      }
      """
    And the current account has 10 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "machines",
          "query": {
            "user": "$users[1].email"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 2 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by machine type on the name attribute using an exact match
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 10 "machines"
    And all "machines" have the following attributes:
      """
      {
        "name": "Sara's MacBook Pro"
      }
      """
    And the first "machine" has the following attributes:
      """
      {
        "name": "John's MacBook Pro"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "machines",
          "query": {
            "name": "John's MacBook Pro"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin performs a search by machine type on the name attribute using a suffix
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 10 "machines"
    And all "machines" have the following attributes:
      """
      {
        "name": "Sara's MacBook Pro"
      }
      """
    And the first "machine" has the following attributes:
      """
      {
        "name": "John's MacBook Pro"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "machines",
          "query": {
            "name": "MacBook Pro"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an array with 10 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product performs a search
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {}
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User performs a search
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {}
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous performs a search
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {}
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs