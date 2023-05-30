@skip/bullet
@api/v1
Feature: Search

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

  Scenario: Admin performs a search using the AND operator
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And "users" 1-5 have the following attributes:
      """
      { "firstName": "John", "lastName": "Doe" }
      """
    And "users" 6-10 have the following attributes:
      """
      { "firstName": "Jane", "lastName": "Doe" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "op": "AND",
          "query": {
            "firstName": "john",
            "lastName": "doe"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 5 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search using the OR operator
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And "users" 1-5 have the following attributes:
      """
      { "firstName": "John", "lastName": "Doe" }
      """
    And "users" 6-10 have the following attributes:
      """
      { "firstName": "Jane", "lastName": "Doe" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "op": "OR",
          "query": {
            "firstName": "john",
            "lastName": "doe"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 10 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by user type
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 15 "users"
    And the first 6 "users" have the following attributes:
      """
      { "lastName": "Doe" }
      """
    And the last 3 "users" have the following attributes:
      """
      { "lastName": "doe" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "lastName": "doe"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 9 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by user type without user.read permissions
    Given the current account is "test1"
    And the current account has 1 "admin"
    And the last "admin" has the following permissions:
      """
      ["license.read", "license.validate"]
      """
    And the current account has 15 "users"
    And the first 2 "users" have the following attributes:
      """
      { "lastName": "Doe" }
      """
    And the last 2 "users" have the following attributes:
      """
      { "lastName": "doe" }
      """
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "lastName": "doe"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by user type using pagination
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first 10 "users" have the following attributes:
      """
      { "lastName": "Doe" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search?page[size]=5&page[number]=1" with the following:
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
    And the response body should be an array with 5 "users"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/search?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/search?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/search?page[number]=2&page[size]=5",
        "meta": {
          "pages": 2,
          "count": 10
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And sidekiq should have 0 "request-log" jobs

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
    And sidekiq should have 0 "request-log" jobs

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
          "query": {
            "name": "test"
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "search type 'accounts' is not supported",
        "source": {
          "pointer": "/meta/type"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
          "query": {
            "token": "%"
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "search type 'tokens' is not supported",
        "source": {
          "pointer": "/meta/type"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
        "detail": "search type 'unknowns' is not supported",
        "source": {
          "pointer": "/meta/type"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
        "detail": "search query 'foo' is not supported for resource type 'users'",
        "source": {
          "pointer": "/meta/query/foo"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 3 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by user type on the email attribute using domain name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.sh"
      }
      """
    And the second "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.net"
      }
      """
    And the third "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.dev"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "email": "@keygen.sh"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by user type on the email attribute using domain name without TLD
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.sh"
      }
      """
    And the second "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.net"
      }
      """
    And the third "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.dev"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "email": "@keygen."
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by user type on the email attribute using local part
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And the first "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.sh"
      }
      """
    And the second "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.net"
      }
      """
    And the third "user" has the following attributes:
      """
      {
        "email": "zeke@keygen.dev"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "email": "zeke@"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "user"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And sidekiq should have 0 "request-log" jobs

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
              "customer_id": "abfdcc31-d5dd-4a20-b982-a81b9d89dec6"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
              "customerId": "51e9a648"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by license type on a metadata object attribute (full)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following metadata:
      """
      {
        "object": {
          "foo": "bar",
          "baz": "qux"
        }
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
              "object": {
                "foo": "bar",
                "baz": "qux"
              }
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by license type on a metadata object attribute (partial)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following metadata:
      """
      {
        "object": {
          "foo": "bar",
          "baz": "qux"
        }
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
              "object": { "baz": "qux" }
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by license type on a metadata array attribute (full)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following metadata:
      """
      {
        "array": [1, 2, 3]
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
              "array": [1, 2, 3]
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by license type on a metadata array attribute (partial)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following metadata:
      """
      {
        "array": [1, 2, 3]
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
              "array": [2]
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by license type on a large key attribute
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "T1RjZ09Ua2dNR1VnWVRFZ016RWdNREFnTnpRZ1ltSWdOMlVnWkRnZ1lqY2daRFFnWkRVZ09Ea2daVEFnWXpJZ05UUWdaRGdnWldRZ05qa2dPRFVnWW1JZ09HTWdaR01nTm1VZ09XUWdabUVnTXpZZ01qa2dOMllnTW1RZ016a2dPR0lnTjJJZ1lqTWdOalFnTURjZ1pHWWdZMlVnWTJRZ01HRWdZelFnWlRnZ1pHWWdORE1nTVRZZ1pqUWdaVFFnWW1VZ1pUY2dZVE1nTURjZ1kyUWdNamdnT1dRZ1pUTWdaREFnTnpZZ1l6RWdOMllnWmprZ1kyTWdaallnWlRRZ1pEVWdOamNnWkRBZ1pqUWdObVFnTkdJZ016VWdNMllnTkRRZ05qY2dNak1nWTJNZ01UY2daRE1nWTJFZ05tSWdaV1FnTWpRZ01ERWdOVE1nTnpBZ01tWWdORElnTlRNZ1lqa2dOVGdnWkdRZ00yRWdaalVnWlRjZ09HVWdaVFVnWTJFZ05qa2dNek1nWmpFZ01qY2dNamNnWmpnZ01ETWdOVGtnTkRBZ09XRWdPVGdnTm1RZ00yRWdNRE1nTVdNZ056VWdPVEVnT0RRZ1pEVWdOamdnTURFZ05tUWdZeklnWWpZZ09HRWdZVGdnTjJJZ05Ua2dPV1VnTURRZ09UTWdaVEVnTURNZ056UWdNVGNnWlRRZ1ptRWdOak1nWm1ZZ05HSWdORFFnTXpNZ01EZ2dOelVnTURZZ01EQWdOemdnTmpFZ00yUWdPRGtnTVRFZ04yRWdZak1nT0RNZ01UZ2dOaklnT0RNZ05EY2dOMlVnTW1NZ1lUWWdZMllnTkRZZ1ltVWdaRGNnWlRrZ1lUVWdNRE1nTm1ZZ1pqRWdNelFnWmpVZ01XWWdOR1VnT0dFZ05UZ2dNV1FnTUdVZ01EUWdNMkVnWVRFZ05ETWdZakFnTUdZZ05EUWdZemtnWlRrZ09ESWdOVEVnTlRFZ09HVWdZbU1nWkdFZ01UVWdNREFnTUdJZ05URWdPVGtnTlRnZ01HVWdPR1FnT1RBZ09UUWdOamNnT0RNZ016UWdaVElnT1dJZ05qZ2daR01nT0RVZ1ltTWdNVGtnT1RJZ1ltRWdNakVnTnpBZ09XTWdaV0lnWW1ZZ09XWWdNRFlnT0RFZ05tWWdaR01nTmprZ04yUWdaalVnWlRZZ1kyTWdNekVnWkRRZ05ETWdZek1nT1RnZ09EVWdNR0VnWVdFZ01UQWdPRElnT0RjZ1lqRWdNbUlnWWpZZ01qVWdOREVnWTJVZ09EVWdOMlFnWldJZ1ltWWdNVEFnWTJZZ1l6Y2dNellnTTJFZ1pETWdPVEVnTXpjZ1pHTWdZelVnTVdVZ05HRWdaR1VnTW1FZ05tVWdZak1nTW1ZZ05HUWdOemNnTVRFZ09HWWdNVGdnWmpZZ09EVWdOelFnTmpZZ01URWdNMlFnWWpnZ01qY2dObVFnTW1VZ04yUWdPVE1nWWpBZ056SWdNV1VnTUdVZ1lXSWdOVGNnTXpFZ01Ea2dZbVVnWWpNZ05XSWdNRGtnTURRZ01ETWdNak1nWm1VZ1ltVWdOVE1nTlRJZ09EWWdaVGNnTm1JZ1l6UWdOemNnTURJZ01Ea2dZMk1nT0RFZ01EUWdPV1lnTmpjZ1l6SWdaV01nTm1ZZ05XTWdNakFnT0RNZ05XVWdNVEFnTkRRZ01qSWdNalFnTWpjZ016Z2daRGNnWVRnZ01USWdNV1VnT1dJZ05EZ2daRFVnWlRFZ056a2dORGtnTlRFZ1pHVWdPRFlnTnpJZ1pUUWdOMlVnWlRJZ05tTWdaak1nTkdNZ01qTWdPVFVnWlRNZ1pqSWdPV0lnWm1JZ09UTWdaVFlnTkRNZ01qVWdaV01nTWpFZ1pqVWdNV1VnWVRFZ09EY2dOMlVnTTJZZ01XRWdPR1VnTjJFZ01EZ2dOREVnTkdRZ09Ua2daRGtnWW1JZ01XTWdOVGtnWmpjZ1lXSWdPR1lnWlRnZ05EWWdOek1nTVRBZ1pqY2dObVVnWlRNZ05tSWdObU1nTldVZ05UWWdOMllnTkdFZ01UUWdNREVnTnpVZ01UWWdOVGdnTWpBZ05HRWdOVFVnTkdJZ09ERWdPVEVnTlRjZ1lUSWdNbU1nT0RJZ01EQWdZbU1nTURJZ01qTWdPREFnWkRrZ1pEQWdZak1nTkRrZ016Y2dZMkVnTURnZ05Ua2dZVE1nTVdNZ01tUWdZamNnTVdZZ1pXUWdOVGtnTm1ZZ1pEWWdPV0VnWWpFZ05qSWdNbVVnTlRjZ09ERWdNVGtnTW1RZ1pEZ2dPR1VnWm1FZ1pUWWdOV1lnTkdJZ1pXSWdNMlVnWXpZZ1lUWWdORGtnTm1VZ05qQWdNamtnWXpJZ1lXRWdOemNnTWpnZ09EY2dNelVnTnpVZ1l6Z2dOMlFnTXpnZ05XTWdaRGdnWXpJZ056VWdOMklnTWpRZ09HTWdNellnT1dNZ05UUWdOak1nTmpVZ1ltTWdZbUVnTVdZZ016QWdaalFnTW1ZZ05qQWdabVlnTnprZ05ETWdOMk1nWW1RZ016Y2dOV1lnTURnZ056Y2dOekVnT1dJZ05Ua2dNV0VnWTJFZ01EWWdORGNnWlRRZ09EQWdPV1lnTTJNZ01tRWdPR0VnTW1JZ1pXTWdOVGNnWXpZZ05ESWdPV1VnTkdJZ1lUQWdZemdnTURVZ1pUVWdPV1VnTkdNZ1pESWdPV1VnWlRjZ00yWWdaR01nWTJRZ01tTWdORGNnWW1JZ09EY2dOVEFnTkdRZ05XWWdPREFnTURnZ1lURWdORE1nTkRJZ04yRWdNelVnTXpJZ016UWdZVGdnTUdRZ1l6SWdOV1FnTXpVZ09XVWdNRFFnTXpVZ01qUWdNalVnT1dJZ1lqVWdOV0VnTlRVZ09XVWdOalFnT0RVZ01UUWdPR1VnWkRNZ05ETWdOREVnWkRNZ016TWdaVGNnWVdNZ05UQWdPRGNnTVRnZ09XTWdaakVnWmpRZ1pUTWdOeklnTnprZ09EUWdabU1nTWpRZ01UY2dPV1VnWlRVZ1ptVWdZamtnWVdJZ09HVWdNbVFnWW1ZZ05HRWdNR0lnWWpVZ01tTWdZamNnTTJNZ05HWWdaREFnWXpnZ056Y2dObVlnTURjZ01XUWdNMkVnTUdVZ09ETWdabUVnTkRJZ01ERWdaak1nT0RrZ1pEVWdNV1FnTVRjZ01EY2dOMk1nT1dNZ1l6SWdaR1VnWWpZZ09XTWdZek1nTURrZ05qUWdaaklnT0RVZ1pqRWdNbVlnTURRZ09XWWdaREVnT0RnZ1pEY2daR0VnT1dZZ05ETWdObVVnTXpNZ016SWdPV1VnTkRjZ1pqZ2dOekFnT1RjZ016TWdOV0lnWm1VZ01tSWdZaklnTWpRZ016SWdNemdnTTJFZ1pUWWdZbVFnWkdFZ05UY2dNR0lnTURFZ05qVWdZMklnTlRJZ01EZ2dOallnTmpVZ1pEWWdPVGNnTURVZ09EWWdaVFlnTURVZ1pETWdORFVnTlRnZ1lqTWdPR0lnWW1NZ01UY2dOallnWXpnZ1pXWWdNbUVnWWpJZ09HWWdNRGdnTW1RZ1pEUWdNalFnWWpRZ01EVWdOVGNnTmpBZ1l6Z2dNelFnT1dZZ05EVWdaVFVnTWpJZ1pESWdNak1nTTJNZ1lqVWdPRGNnWW1VZ1pUWWdPRE1nWlRFZ056SWdNakFnT0RRZ09XWWdabVVnTTJFZ09EQWdZVFVnTkRRZ1pUZ2dOelFnT1RrZ1lqY2dZV1VnTm1VZ016WWdNemNnT0dZZ01tSWdZbUlnTmpjZ09UZ2dObVlnTm1RZ05qRWdZemtnTVRJZ05Ea2dPRElnTTJVZ1pqRWdZbVVnTldVZ1lUUWdPVFlnWkdJZ1pHRWdOV0lnTkRJZ09UQWdOek1nTVRFZ1ptUWdZMk1nTWpJZ05HTWdNV1FnT1RBZ1l6Y2dNREVnTnpZZ01UZ2dZMllnTURBZ1lqUWdZMlFnWldFZ1pHWWdZamNnT1RRZ09HRWdNelVnWVRRZ01qVWdORFVnWmpZZ1pUSWdaR0lnTnpBZ09USWdaRFVnTVRjZ04yTWdOVEFnTjJVZ1l6TWdZbVFnT0RVZ01Ua2dNbU1nTlRNZ1pHWWdOemNnT0RZZ1pqTWdOREFnWW1RZ1l6VWdabVFnTldRZ01UQWdaR0lnTURFZ01HTWdOV1FnWldZZ05UVWdOeklnT1RjZ01XUWdNRGNnWmpVZ1pUY2dZamNnTkdVZ05XSWdZekVnTTJNZ05qUWdOMllnTURJZ1pUUWdPREVnWVRVZ1l6QWdNV0lnWVRrZ1pESWdNVGdnWVRFZ05HWWdNellnWldJZ05EY2daRFVnWXpZZ056a2dOemNnWm1ZZ1l6WWdNRFlnWW1JZ1pEY2dZV0lnWWpVZ09HTWdPRE1nT1RRZ1lUQWdOalVnWWpRZ1pHWWdPV1FnT1RjZ09EVWdZMllnWlRNZ01EUWdaRGtnTVRNZ1pqWWdORFVnTkRJZ01tTWdZekVnTWpFZ05EWWdaVElnWmpjZ00yUWdObUVnWmpVZ09Ua2dZV1FnWXpZZ05UWWdaVEVnT0RjZ056SWdaREVnWW1ZZ01UWWdPVFVnTlRBZ05ETWdNREFnTmpVZ1pHVWdaR0lnWmpnZ1l6a2dNelVnTjJFZ056Z2dPR01nT0dJZ1l6Y2dNeklnTlRjZ05UY2dOaklnWlRnZ05qY2dOelVnWW1JZ1lqY2daV0lnT0RjZ05qY2dPV0VnTVdRZ01EZ2dNVGdnTnpVZ05qY2dORGdnTjJZZ05URWdORElnTW1JZ1ptVWdaRGdnTnpNZ09XWWdObUVnTlRRZ1pXVWdZMlFnTVRjZ00yTWdNVGtnTXpJZ1lqSWdPV1lnTWpBZ1lqWWdOemdnTVRRZ09UVWdORFlnTTJJZ1ptUWdNREFnWlRJZ1lqZ2dOV1VnWW1RZ1lUa2dOVEFnTkRBZ05ETWdNMlVnWlRJZ1l6Z2dPV0lnWmpJZ1l6Y2dOMk1nTm1VZ01qZ2daVEVnTlRBZ1lqVWdZelVnWVdZZ1l6VWdNbUlnWVRrZ1ptWWdOamdnWlRJZ09EQWdZelFnTkRBZ1lUWWdZbU1nWm1JZ056QWdOalVnTWpNZ01EQWdNekFnWkdZZ09EY2dORGtnT1RFZ05qVWdNak1nWXpjZ01ERWdObVlnTUdNZ05UUWdOalFnWkRJZ00yVWdNVE1nTVdNZ1l6SWdOVEFnTlRjZ016RWdOR1lnT0RZZ1pUQWdOVGdnWVRFZ01EWWdOMlFnTmpRZ1lqUWdOalFnWkdRZ01XTWdZV0VnTURJZ1pHSWdZMklnTWpRZ01HRWdObUVnWlRJZ01qTWdNVE1nWXpjZ01tUWdNbVFnTUdNZ09ERWdOMlVnT0dVZ01qZ2dORElnT1RFZ056UWdOMlVnTkdRZ1ltTWdOMlVnWXpnZ01qSWdNekVnTXpJZ1pqQWdOMllnWmpnZ1pUUWdPVEVnWVdJZ04yUWdNalVnT0dZZ1ltVWdaR1VnTWpVZ09UTWdObVVnT1RNZ01EUWdNak1nWm1VZ05XUWdNVFVnTlRrZ05EY2dZbVlnWm1FZ1pXUWdNV01nWkRrZ1l6WWdabVFnWWpFZ01Ua2dOakFnWmpVZ09EVWdORGtnT1RJZ01HWWdObVVnTURJZ1kyRWdNV0lnT0RNZ1pURWdZMllnTURFZ1lUa2dNakFnTTJVZ05UUWdaR0lnTWpnZ1ltVWdPV0lnTWpjZ01HWWdNRE1nWXpNZ01qY2dOREFnWVdVZ1lUY2dZeklnTm1VZ05UTWdZbVVnTjJZZ1pEa2daR0VnTWpZZ01USWdOVEFnTWprZ05qVWdOV1VnTnpFZ1pHVWdZV1VnT0RJZ1l6UWdPVElnTWpJZ01tTWdNamNnWldZZ05qVWdZMlFnTVRJZ04yTWdaVE1nTlRFZ1pqY2dZVFFnTUdJZ016a2daRGdnWVdNZ05qY2dPVGtnWVRJZ1kySWdaVE1nWXpRZ1pEVWdOallnTmpVZ09HVWdaVElnTURnZ05qWWdPR1FnWmpNZ09ESWdZekVnTUdZZ01EQWdNR1VnWXpjZ01qSWdaRGNnTTJVZ1pEQWdOVFFnWlRZZ01qWWdaV1FnT1RVZ016UWdZemdnWXpRZ1lqRWdZamNnTXpnZ016RWdNREFnWVRBZ1lUQWdObUVnTjJFZ1lUQWdNR1FnT0RZZ01qa2dNamdnWVRnZ09HTWdOelFnWlRFZ1pETWdOVFFnTTJRZ09UQWdNREVnTkdRZ1pUY2dOMlVnTm1ZZ01UZ2daak1nTmpRZ1pUa2daRFFnTVdJZ09ERWdaR1lnTTJFZ05EY2dNVFlnT0dZZ1pqa2dZelVnWkRnZ09EVWdOREFnTnpFZ00yWWdNelFnWkdFZ05EVWdZakFnTmpFZ1pEQWdZVGtnTXpjZ09XVWdOVEFnWkRVZ05HVWdZbUVnWTJVZ1lqTWdZMlFnTVRJZ09EVWdZekVnTWprZ01tSWdNR1VnWmpJZ1ptUWdNak1nWTJFZ1ltRWdPVEVnTjJJZ1pUWWdOMk1nWkRFZ05UVWdORGNnWlRnZ1l6TWdNbVlnTWpNZ04ySWdabVFnWlRBZ01XVWdOaklnWkdNZ05UY2dOamtnTmpZZ05USWdaamNnTnpjZ016Z2dOekVnWWpVZ1ptRWdZVGtnWVdRZ09HTWdPREVnTlRFZ016Y2dNMlVnTXpZZ09UTWdOVGtnTVdJZ05URWdaaklnTmpFZ1ltRWdOemdnT1RVZ01qVWdNVEFnT1RFZ1pXTWdNR0lnWkdVZ1lXRWdPREFnTTJVZ09HVWdOMklnTVRZZ05ESWdZVFVnTVRNZ1pEY2dNallnTWprZ1pEa2daV1lnTTJNZ056UWdZMk1nWWpRZ1lqUWdaVFVnWkRBZ1ptWWdOeklnWm1FZ05UWWdZVElnTjJNZ01HSWdPVFFnWXpjZ05qTWdOVFFnTmpVZ05qSWdOaklnT0RrZ09Ua2dNV0lnTWprZ09HWWdaVE1nWW1ZZ1pUY2dOVElnT0dRZ1lUSWdNV1lnTkRRZ01UY2dZVGNnTlRNZ09ETWdZV1VnWVRnZ05Ea2dNV0lnWVRVZ1l6TWdNemtnWm1VZ016TWdPVGdnTURRZ1lUSWdNalFnTkRBZ1lqRWdZMllnTkRjZ1pXSWdOamNnTXpnZ05UWWdaV1VnWkRZZ01qTWdORFVnTVRRZ1lXUWdaV01nTkRJZ1lXVWdNVEFnWkRrZ05EY2dNalVnWVRBZ05HRWdZV0VnTm1JZ01XVWdNV0VnTTJRZ1kyVWdNVFVnWldRZ1pEZ2dPR1lnWWpnZ04yVWdZV0lnWlRrZ1pqQWdOV0lnTW1ZZ04ySWdOMklnTWprZ01ESWdZVE1nWW1ZZ1pXSWdaalFnWXpNZ01XTWdaalFnTjJNZ01XVWdOR1VnWkRjZ1ptTWdaamNnTTJVZ1pURWdNR1VnWm1VZ05qZ2daRGNnT1RZZ1lUY2dNemNnWmpFZ01tWWdOV01nTlRBZ05XRWdaakVnWldNZ1kyRWdaR1FnWVRnZ05UVWdNek1nTm1NZ01XRWdOMllnT1dRZ00yVWdOR1VnTVRVZ09ERWdOVFlnT1RFZ1pXSWdORFVnWVRjZ05qUWdaRFFnTVRVZ04yUWdabU1nTmpJZ1ptTWdOR1VnTkRRZ09UUWdZMklnTlRBZ1pqY2dPRFlnWldVZ05UQWdOamNnT0dVZ01XVWdNelFnTURVZ1lqUWdPVFlnTm1FZ01HTWdORElnWlRnZ1lUa2daamtnTWpVZ05EWWdNV1lnTlRNZ1lXWWdZVFVnTkRZZ05XVWdaVEFnT1RnZ1l6SWdaakVnWkdRZ05USWdNV1VnTjJRZ1lXTWdaRGNnTVRRZ05ERWdZVEFnWlRJZ1pqWWdZamtnWVdZZ05Ua2dOVGNnWXpVZ01XSWdNR01nWXpFZ09UWWdaRGNnWVRjZ09UUWdPR0VnT1RZZ09UTWdNV1lnTTJNZ01USWdZVEVnWW1FZ01HVWdOVEVnWkRNZ1lqY2dNMklnTW1FZ1lUY2dPR0lnT0dFZ1lqWWdZeklnWVRjZ05EUWdaVFVnWlRVZ016QWdORE1nTlRBZ1pHWWdOV1FnWmpBZ1pESWdNV1FnWm1JZ05qY2dNellnTXpZZ1lqVWdZV0VnT1dJZ00ySWdNemtnT1RNZ05HRWdNemtnTURBZ01tVWdOR0lnWXpVZ016UWdOamtnTTJRZ09UY2daRElnWldVZ04yUWdaR1FnTURRZ05qVWdZVFVnWkRBZ1pHRWdabVVnTVRnZ05qa2daV0VnTW1JZ1pUUWdNVEFnT0RJZ09XVWdabU1nTXprZ1pXSWdOek1nWkdNZ1lqRWdZak1nTWpVZ09XRWdaREVnT0dNZ1lURWdZek1nWmpFZ1l6VWdabU1nTkdJZ1ltTWdNRE1nTmpnZ056QWdaR0lnWTJNZ09XRWdaV1VnTXpjZ1pqQWdNemdnWmpNZ05EVWdaak1nT1RRZ09HVWdZek1nWXpRZ09EVWdZV01nTkRZZ01ETWdaR0lnWlRjZ1pXVWdZalVnWmpRZ1pUY2dOalFnWmpZZ05XWWdObVVnT0RNZ05UWWdPR1VnTmpjZ05qY2dORGNnTkRFZ1l6Z2dPV1FnWVRrZ1ptTWdNamtnTUdVZ09EVWdOelFnTldNZ1lURWdNallnTVdNZ016Y2dZVFFnTlRrZ01qWWdNVE1nT0RrZ1lqSWdZVGNnTW1VZ1pUSWdOREVnTXpZZ01ERWdaVFlnWkdVZ00yWWdNelFnTVdJZ1pUVWdPVGdnWWprZ1pUUWdPVGtnTkRBZ01UQWdNakVnTm1JZ1lqY2dOR1FnWW1VZ056a2dPVFlnWVdVZ01XSWdZVE1nTXpBZ01UTWdZVGNnTkdZZ1ptRWdZV1lnTjJRZ09HTWdPV1lnWW1RZ1pEWWdaamdnT1dNZ1ptUWdNemdnTW1NZ05USWdNRE1nTkdVZ1ptUWdaV1VnTUdZZ1lqTWdNRFVnTjJZZ09HRWdPRElnTnpRZ05qWWdaR1FnTUdZZ1pEWWdNRGdnT0RJZ1pUQWdNR1VnTkRJZ1pEZ2dPV1VnT1RjZ05qUWdPVElnTTJZZ1ltRWdOekVnTVRjZ1lUTWdZVEVnT0RnZ01UWWdNV0VnWkdJZ1lqZ2dOamtnTkRnZ1kyWWdaR1FnT1RFZ01tWWdNMlFnT0RBZ01HSWdaamNnTmpVZ01Ua2dORFlnWWpZZ05Ua2daVFlnTUdZZ05ERWdORGdnWTJRZ016VWdZekVnT1RBZ01HRWdZak1nWTJJZ01qSWdOakFnT0RnZ05ERWdOR1FnTURFZ1kyTWdNallnTUdVZ09Ea2dOVE1nTUdNZ04yVWdOellnWWpnZ01Ua2dOalVnT0dVZ05qWWdZamdnWXpVZ09Ea2dZMklnTldJZ09XSWdNREFnTjJFZ1pXVWdOMlFnTnpjZ1kyRWdNREVnT1RjZ1l6QWdNekFnWVRrZ05EUWdZMllnTVdZZ1pXRWdNREVnT1dNZ056Y2dOMklnTlRFZ05HSWdNVFlnWVRJZ1pEa2dNemdnWVRNZ05UVWdOallnT1dZZ016QWdaVFlnWldFZ1pXRWdabUVnTnpZZ05UWWdNamtnT0RNZ05tVWdPVFFnTTJRZ05USWdZbU1nWkRFZ1lXTWdaV01nTmpZZ1lUSWdNRGdnTnpJZ1pqQWdNRE1nTUdZZ1pUTWdaVEVnT1RBZ1pqUWdOemdnWXpnZ09UTWdPR01nWldFZ016UWdaallnTWpZZ01HTWdPRFlnT0RRZ00yTWdZalFnTlRRZ05ERWdabUlnT1RFZ01tVWdNREFnWm1VZ01tUWdPV1lnWkdRZ1pETWdabUVnTXpBZ1pUZ2daR1VnWkRBZ1lXSWdaVGtnTnpJZ01UTWdaallnTWpJZ05HRWdNallnTTJJZ016RWdPREFnTXprZ1lqZ2dOV1lnWm1ZZ1ltUWdZVEVnTm1VZ01UY2daak1nTlRBZ05URWdOV0lnWmprZ00yUWdObU1nWVRJZ01XRWdNR1lnTmpFZ1pURWdOMllnTjJFZ1kyWWdZakFnWm1VZ01XVWdZak1nWlRjZ01XVWdOemdnTkRrZ1pUY2dNR01nTldFZ01HSWdaalFnTVdRZ05EY2dNVElnTVRFZ01qQWdNbUlnTWprZ1l6VWdPVGdnWWpJZ1pXVWdNR1lnT1dFZ04yVWdPR0lnT1RBZ016a2dObUlnWmpjZ00yUWdNalFnWW1ZZ01qa2daRFlnT0RRZ09URWdaRElnWW1FZ01HUWdZMkVnWkRNZ05URWdPREVnT1dVZ1pETWdPRFVnWkRrZ01qa2dOMklnTnpZZ04yTWdOelFnT0dZZ1lqQWdaamdnTVRrZ01UY2dZakFnTW1ZZ05UY2dPR0lnT1RVZ1ptVWdOR1VnT0RjZ05HUWdOakVnWm1JZ1pHWWdObVFnTldJZ01UZ2dOV01nTjJVZ01URWdOelVnTkRnZ1pHWWdZVGtnTVRBZ1lUUWdOREVnWVdRZ1lXSWdNVGtnTTJVZ056SWdOVGdnT0dNZ09HRWdOakVnWWpVZ1pEWWdZak1nWVRJZ09EQWdZelVnWldFZ09XSWdNV1FnTlRZZ1kyVWdOMllnT0RnZ1ltUWdPRGNnTkRjZ1pqUWdOR0lnWkRrZ01EY2dPR0VnWmpnZ016VWdaVGdnWmpZZ05ETWdZbUlnWmpFZ01qUWdaRElnTVRVZ1lqWWdZVGdnTkRrZ01qY2dNemNnWW1NZ01EWWdNamdnT1RnZ05XWWdaV01nTVRZZ01qZ2dOR0VnWm1JZ01USWdNV1VnT0dVZ1pURWdZVFlnTkRVZ016TWdNakFnWkRnZ05EVWdaakVnTVdZZ1pHSWdNalVnTmpnZ09EUWdPV0lnWlRNZ1pEVWdOREFnTVdRZ1kyVWdNelFnTm1FZ1pUSWdPVFlnWWpNZ1pEVWdZelFnWmpZZ01tTWdNVEVnWkRRZ1pEZ2dNbVVnWW1FZ1lUTWdZamtnWm1ZZ056VWdZV1FnTlRFZ09XSWdOamNnTXprZ09ESWdaR0lnTWpNZ1ptRWdZemdnTURNZ09USWdPV0lnWXprZ01tUWdNRGtnT0dJZ05EWWdPR0VnTkRnZ1pERWdPRFFnTUdVZ05EVWdPRFVnWWpNZ04yRWdNbVFnTWpRZ01HWWdaRFlnWmpjZ01tUWdPV0VnWkdFZ00yVWdPVElnT1dVZ01qVWdNemNnTXpBZ1pUa2daakFnWkdRZ1pqWWdZemNnWW1NZ05UVWdaRFFnTlRRZ01UTWdOV01nWXpVZ1ltVWdNekVnTWpnZ016QWdZamNnTjJJZ05EVWdOV1lnTW1ZZ01UUWdOaklnWVdVZ05EY2dOV1lnT1dZZ05tVWdaREVnTW1VZ01tWWdOR0VnWWpjZ05EQWdNMlVnWVRVZ056a2dOemNnT1RRZ1lXVWdNalVnTWpnZ1lqSWdNMlVnWXpBZ1lXSWdZV0VnTWpFZ01qRWdPVEVnWVRRZ09EZ2daR0VnT1RNZ016a2daaklnT1RjZ01HUWdaVGdnTmpnZ01HTWdaalVnT0RRZ00ySWdZellnTjJNZ05XSWdaVE1nWkRZZ1pEZ2dNREFnT0RRZ01EY2dOVEFnWTJJZ01XSWdNV0lnTnpFZ09URWdOMklnWldNZ1pXRWdObVFnWXpNZ09URWdNVGNnTVRBZ1l6WWdNbUlnWlRRZ00yRWdNVGdnTUdFZ05UUWdNV1lnTmpjZ1pqVWdaak1nWlRFZ09USWdOV1FnWVRVZ01UVWdPV1VnTm1NZ056RWdOVFVnTXpNZ1pURWdNVGtnTW1VZ016RWdOamtnT0RnZ01qa2daR01nTVdFZ1lqQWdOak1nWlRnZ01UZ2dZbVlnTkdZZ01ESWdZVFlnTURVZ1pXVWdaV0VnWXpBZ04yWWdOemdnTWpnZ01XUWdZamtnTXpNZ05qSWdNekVnTWpFZ05HSWdOalFnT0dNZ1ltVWdZVEVnTkdZZ1pqTWdaV1FnTmpVZ1pqTWdaVGtnWldJZ1pEY2dNekVnTmpjZ056QWdOVGtnTnprZ05qZ2dOelVnTURrZ09URWdPRFlnTkRnZ05qRWdPVGtnWldZZ1ptSWdZbVlnTXpFZ09EUWdOMllnWVRnZ09XRWdZelFnT0RJZ1kyRWdZVElnTVdZZ01qVWdNRElnTlRZZ016VWdZV1VnTnpVZ05XTWdOV0lnTXpRZ05EWWdOREFnTXpnZ1lqRWdaV1lnWkdVZ01qVWdPREVnTldNZ01XWWdNV1FnTnpRZ01qRWdNV01nWW1VZ1l6TWdPREVnTldZZ05qZ2daREFnTVRFZ1pqZ2dOak1nWTJFZ05HVWdORElnTURVZ09XVWdOVGtnTXpjZ01UY2dZVFFnWm1ZZ01XUWdPVEFnTURJZ01qTWdZMkVnTlRJZ056RWdPV01nTVRBZ1ltRWdOalVnWmpRZ01HTWdPREFnTlRFZ05HUWdNak1nWkdFZ01tSWdPRFFnTjJNZ016RWdNVE1nTlRBZ1pUSWdZekVnWTJRZ05ESWdOVGdnTVRNZ05qY2dPRGdnWWpNZ01UQWdZVGdnTTJNZ1pHVWdNalVnTVRVZ05UTWdaREVnTUdVZ05qVWdNVEFnT0dVZ05XSWdZalFnWkdFZ01XVWdOR1FnT0RZZ1lqRWdOemtnWmpBZ01UZ2dOelVnWW1NZ1pqRWdaalVnTXpVZ01Ua2dOV1FnWXpRZ1lqa2daRGNnTm1JZ05XSWdPV01nTTJFZ01EUWdOVElnTlRJZ1pERWdaREFnWlRnZ01ERWdZMlFnWW1JZ016QWdORE1nTVRVZ01HUWdOallnTm1NZ01qUWdPVGtnTlRjZ01XVWdZelFnTkdVZ056Y2dabVVnWVRnZ00yRWdOMk1nTVRBZ09HRWdObUVnTjJRZ05UZ2dNalVnT1RnZ04yRWdNMllnWldJZ056RWdaakFnWVRjZ1lUa2dZMklnWmprZ1pHWWdaRFVnWW1VZ09XWWdNelFnWlRFZ1pUa2dOVEVnWlRJZ1l6QWdOamtnTjJFZ056SWdaR01nWW1JZ1ltSWdZalFnTWpZZ09UQWdOalVnTWprZ016TWdZMklnT0dNZ01EVWdNV1lnTnpZZ1ptTWdOR1VnWVdFZ01tWWdOemdnWlRjZ01URWdaVFFnTmprZ1ptTWdaallnTWpBZ01XTWdOMlFnTTJZZ09Ua2dOalVnT1dJZ1pXVWdNMk1nWVdJZ01HUWdNemtnTVRrZ1pUVWdaR0lnWVdVZ05ETWdZallnTkRjZ1l6Y2dZekFnWXpJZ01qVWdZVEFnT1dRZ1ltUWdZemNnTkdVZ1kyWWdOelFnWmpBZ01qRWdZV1VnWVRRZ1l6Z2dPRGdnWVRrZ1lqUWdaVFVnTVRBZ09USWdNVE1nTWpZZ1lXUWdORFlnWVRVZ1kyTWdaR01nWXpVZ01qSWdORGdnTlRZZ09HSWdNRFFnT1dRZ05XVWdNMk1nWm1FZ1lqTWdZMlFnTVdRZ01tTWdaR1lnTVRnZ09XTWdPR1FnWkRjZ016TWdNemdnWWpJZ09HWWdZalFnT0RBZ056SWdORGNnTVdFZ04yUWdaRFlnWmpBZ05tUWdOek1nTldJZ05UUWdOekFnTlRNZ1pXVWdZVElnWVdJZ09UWWdZamdnWWpZZ05UY2dZVGNnWm1JZ1pqRWdOR1lnWVRRZ056Z2daVFFnTWpJZ1pHVWdaRGdnTnpBZ056Z2dNRFVnTkRVZ04yVWdNellnWmpZZ05XVWdZMlVnTjJRZ05HRWdOek1nT0dRZ1lqSWdaR0lnWVdZZ01UTWdOV0lnTVRRZ1ptSWdNR01nTUdJZ01ESWdZMklnTVRNZ01qTWdaV0VnWm1JZ1lqa2dNRGdnWVRnZ1pEQWdNallnTlRZZ05tRWdNMlVnTTJNZ05EZ2dPRGdnTlRrZ04yRWdNelFnTXpRZ1ltVWdZbVFnWlRVZ05ETWdaamNnT1RBZ056WWdNelVnTTJFZ01XRWdOek1nTURVZ1pUQWdPRGdnWVdRZ1l6TWdNRFFnWlRZZ05URWdaR01nTTJRZ1kyTWdaVGNnTVRBZ05qY2dabVFnTldRZ1l6Y2daRFlnTXpZZ1pUVWdPV1FnTlRFZ05USWdaVFlnTXpZZ05qUWdPVGdnWmpZZ1lUa2dNV1FnTWpJZ1kyVWdaV1VnT0RZZ09XTWdNallnTnpZZ01qUWdaV0VnTldFZ1ltTWdNbUVnTVRVZ01tUWdPRFlnTkRBZ1l6Y2dOek1nT1RjZ1lXRWdaVE1nT1RjZ05HWWdZV01nTjJVZ09XWWdZeklnWldVZ1pUVWdOR0VnTkRnZ1pHWWdaREVnTldFZ01EZ2daRElnTlRrZ01UTWdNek1nTkdFZ01EY2dZemdnWldVZ1pEVWdObVFnTm1ZZ05HTWdaVGtnTWpRZ016RWdOVEVnTldFZ056Y2dOVFlnWkdFZ01qSWdObUlnWVRnZ1lqSWdZellnTjJNZ1lqa2dNelFnTjJNZ05qUWdOVElnTnpVZ1l6Z2dORElnTVdFZ01HVWdNRFFnTURnZ01qWWdNMlFnTWpRZ1lUY2dOVEVnT1dRZ01ERWdZVGdnTjJNZ05EWWdOVEFnTmpnZ1lqVWdOR0lnWmpFZ1lUSWdaVEFnTldVZ05tTWdZekVnT1RNZ01ESWdOelFnWlRZZ09XWWdNamtnWWpNZ05URWdaaklnWVdJZ1pqa2dOMkVnTW1RZ01EQWdPRFFnTkRFZ1pqUWdNRFlnWkRBZ1ptWWdNREVnTnpZZ1l6Z2dNRGdnWm1ZZ09XTWdZMk1nTVdZZ05Ua2daamtnT0RZZ01XUWdObVFnWTJRZ1l6Z2dOR1lnTmpnZ00yUWdZVGtnWVdVZ05UZ2daakFnTWprZ1pqWWdPR0VnTnpnZ1lURWdaRGdnTURnZ01Ua2dNVFFnWWpJZ09ERWdOallnWWpJZ1lXRWdNR1VnTlRZZ1pESWdZV1VnT0RZZ1pURWdZemtnTURNZ1pUSWdORElnTVdZZ056WWdNVE1nWkdVZ056Y2dZaklnWlRVZ05ERWdabVFnTUdNZ1lqRWdOelFnWWpVZ1pHVWdaRFVnWkRNZ01XSWdZelFnTVRNZ1ltWWdPRFFnWTJNZ1pEVWdZV01nWVdVZ1l6SWdNV1FnTm1NZ1l6VWdPV1lnWVRjZ05UUWdNVFlnTnpnZ1kySWdZelFnTjJRZ1l6QWdNalVnWXpNZ09UQWdOVGNnTkRnlear"
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
    And the response body should be an array with 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "license"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 2 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 7 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 5 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "policy"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 2 "policies"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by release type on the product relationship by name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "name": "Apex Legends" }
      """
    And the second "product" has the following attributes:
      """
      { "name": "Titanfall 2" }
      """
    And the third "product" has the following attributes:
      """
      { "name": "Titanfall" }
      """
    And the current account has 5 "releases"
    And the first "release" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the second "release" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the third "release" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "releases",
          "query": {
            "product": "Titanfall"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 5 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 2 "machines"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 1 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
    And the response body should be an array with 10 "machine"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on ID (full)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 100 "request-logs"
    And the first "request-log" has the following attributes:
      """
      { "id": "3307d9b3-59c8-4a78-b2e3-4cf95232a904" }
      """
    And the second "request-log" has the following attributes:
      """
      { "id": "3307d9b3-49f6-42df-ad1a-ac2ba1b0ae1b" }
      """
    And the third "request-log" has the following attributes:
      """
      { "id": "3307d9b3-da36-4a92-863d-68880c4cfea1" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "id": "3307d9b3-59c8-4a78-b2e3-4cf95232a904"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "request-log"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on ID (partial)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 100 "request-logs"
    And the first "request-log" has the following attributes:
      """
      { "id": "3307d9b3-59c8-4a78-b2e3-4cf95232a904" }
      """
    And the second "request-log" has the following attributes:
      """
      { "id": "3307d9b3-49f6-42df-ad1a-ac2ba1b0ae1b" }
      """
    And the third "request-log" has the following attributes:
      """
      { "id": "3307d9b3-da36-4a92-863d-68880c4cfea1" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "id": "3307d9b3"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on the url attribute (full)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 100 "request-logs"
    And 9 "request-logs" have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses/actions/validate-key",
        "method": "POST"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "url": "/v1/accounts/test1/licenses/actions/validate-key"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 9 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on the url attribute (partial)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 25 "request-logs"
    And 3 "request-logs" have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses/actions/validate-key",
        "method": "POST"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-log",
          "query": {
            "url": "/validate-key"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on the IP attribute (full, IPv4)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 100 "request-logs"
    And "request-logs" 1-4 have the following attributes:
      """
      {
        "ip": "192.168.1.1"
      }
      """
    And "request-logs" 5-10 have the following attributes:
      """
      {
        "ip": "192.168.0.1"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "ip": "192.168.1.1"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 4 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on the IP attribute (partial, IPv4)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 100 "request-logs"
    And "request-logs" 1-3 have the following attributes:
      """
      {
        "ip": "192.168.1.1"
      }
      """
    And "request-logs" 4-10 have the following attributes:
      """
      {
        "ip": "192.168.0.1"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "ip": "192.168"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 10 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on the IP attribute (full, IPv6)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 100 "request-logs"
    And "request-logs" 1-2 have the following attributes:
      """
      {
        "ip": "2600:1700:3e90:a450:89df:f64:4791:6a55"
      }
      """
    And "request-logs" 3-10 have the following attributes:
      """
      {
        "ip": "2600:1700:3e90:a450:89df:f91:7211:5c81"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "ip": "2600:1700:3e90:a450:89df:f64:4791:6a55"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 2 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on the IP attribute (partial, IPv6)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 100 "request-logs"
    And "request-logs" 1-7 have the following attributes:
      """
      {
        "ip": "2600:1700:3e90:a450:89df:f64:4791:6a55"
      }
      """
    And "request-logs" 8-10 have the following attributes:
      """
      {
        "ip": "2600:1700:3e90:a450:89df:f91:7211:5c81"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "ip": "2600:1700:3e90:a450:89df"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 10 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on resource ID (full)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 25 "request-logs"
    And 8 "request-logs" have the following attributes:
      """
      {
        "resourceId": "671b5c1e-df06-4479-b8b0-94303149a660",
        "resourceType": "License"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-log",
          "query": {
            "resourceId": "671b5c1e-df06-4479-b8b0-94303149a660"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 8 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on resource ID (partial)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 25 "request-logs"
    And 8 "request-logs" have the following attributes:
      """
      {
        "resourceId": "671b5c1e-df06-4479-b8b0-94303149a660",
        "resourceType": "License"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-log",
          "query": {
            "resourceId": "671b5c1e"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 8 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on requestor ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 29 "request-logs"
    And the first "request-log" has the following attributes:
      """
      {
        "requestorId": "a499bb93-9902-4b52-8a04-76944ad7f660",
        "requestorType": "User"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-log",
          "query": {
            "requestorId": "a499bb93-9902-4b52-8a04-76944ad7f660"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 1 "request-log"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by request log type on multiple attributes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 5 "request-logs"
    And all "request-logs" have the following attributes:
      """
      {
        "url": "/v1/accounts/test1/licenses/actions/validate-key",
        "method": "POST",
        "status": 200
      }
      """
    And the first "request-log" has the following attributes:
      """
      { "ip": "192.168.1.1" }
      """
    And the second "request-log" has the following attributes:
      """
      { "ip": "192.168.1.1", "status": 400 }
      """
    And the third "request-log" has the following attributes:
      """
      { "ip": "192.168.0.1" }
      """
    And the fourth "request-log" has the following attributes:
      """
      { "ip": "192.168.0.1" }
      """
    And the fifth "request-log" has the following attributes:
      """
      { "ip": "192.168.1.1" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "requestLog",
          "query": {
            "url": "/validate-key",
            "method": "POST",
            "status": 200,
            "ip": "192.168.1.1"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 2 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search by group type on name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "groups"
    And the first "group" has the following attributes:
      """
      { "name": "ACME G1" }
      """
    And the second "group" has the following attributes:
      """
      { "name": "Foo G1" }
      """
    And the third "group" has the following attributes:
      """
      { "name": "ACME G2" }
      """
    And the fourth "group" has the following attributes:
      """
      { "name": "Bar G1" }
      """
    And the fifth "group" has the following attributes:
      """
      { "name": "ACME G3" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "groups",
          "query": {
            "name": "ACME"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 3 "groups"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search with an empty query
    Given the current account is "test1"
    And I am an admin of account "test1"
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
    Then the response status should be "400"
    And the response body should be an array of errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "cannot be blank",
        "source": {
          "pointer": "/meta/query"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search with a empty value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "users"
    And the first 2 "users" have the following attributes:
      """
      { "lastName": "Doe" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "lastName": ""
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "search query for 'lastName' is too small (minimum 3 characters)",
        "source": {
          "pointer": "/meta/query/lastName"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin performs a search with a nil value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "users"
    And the first 2 "users" have the following attributes:
      """
      { "lastName": "Doe" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "lastName": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 0 "users"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment performs a search
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search?environment=shared" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "email": "test@keygen.example"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
          "query": {
            "email": "test@keygen.example"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

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
          "query": {
            "email": "test@keygen.example"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: License performs a search
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "email": "test@keygen.example"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous performs a search
    Given the current account is "test1"
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "users",
          "query": {
            "email": "test@keygen.example"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to perform an SQL injection
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "request-log"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/search" with the following:
      """
      {
        "meta": {
          "type": "request-logs",
          "query": {
            "ip": "'; select pg_terminate_backend(pg_backend_pid()); --"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 0 "request-logs"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs
