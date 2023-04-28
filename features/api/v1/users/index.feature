@api/v1
Feature: List users

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
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "403"

  Scenario: Admin retrieves all users for their account (active)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And the current account has 15 "licenses" for existing "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Admin retrieves all users for their account (inactive)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And all "users" have the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the current account has 15 "licenses" for existing "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Developer retrieves all users for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Sales retrieves all users for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Support retrieves all users for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Read-only retrieves all users for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Admin retrieves a paginated list of users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 21 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "users"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/users?page[number]=2&page[size]=5",
        "next": "/v1/accounts/test1/users?page[number]=3&page[size]=5",
        "prev": "/v1/accounts/test1/users?page[number]=1&page[size]=5",
        "first": "/v1/accounts/test1/users?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/users?page[number]=5&page[size]=5",
        "meta": {
          "pages": 5,
          "count": 21
        }
      }
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a paginated list of users with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of users with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of users with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all users without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 10 "users"

  Scenario: Admin retrieves all users with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "users"

  Scenario: Admin retrieves all users with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "users"

  Scenario: Admin retrieves all users with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all users with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?limit=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves all users scoped to a specific product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the second "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 3 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]", "policyId": "$policies[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]", "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?product=$products[0]"
    Then the response status should be "200"
    And the response body should be an array with 2 "users"

 Scenario: Admin retrieves all active (assigned) users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 9 "users"
    And the current account has 3 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?active=true"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Admin retrieves all inactive (unassigned) users
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 9 "users"
    And the current account has 2 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?active=false"
    Then the response status should be "200"
    And the response body should be an array with 7 "users"

  Scenario: Admin retrieves all users filtered by metadata customer email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 9 "users"
    # NOTE(ezekg) First user is the current admin
    And the second "user" has the following attributes:
      """
      {
        "metadata": {
          "customer": "john.doe@example.com"
        }
      }
      """
    And the third "user" has the following attributes:
      """
      {
        "metadata": {
          "customer": "jane.doe@example.com"
        }
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?metadata[customer]=john.doe@example.com"
    Then the response status should be "200"
    And the response body should be an array with 1 "user"

  Scenario: Admin retrieves all users filtered by metadata customer email (excluding admins)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 9 "users"
    And the first "user" has the following attributes:
      """
      {
        "metadata": {
          "customer": "john.doe@example.com"
        }
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?metadata[customer]=john.doe@example.com"
    Then the response status should be "200"
    And the response body should be an array with 0 "users"

  Scenario: Admin retrieves all users filtered by metadata customer ID and product ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 9 "users"
    # NOTE(ezekg) First user is the current admin
    And the second "user" has the following attributes:
      """
      {
        "metadata": {
          "customerId": "a81b9d89dec6"
        }
      }
      """
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the second "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]", "policyId": "$policies[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]", "policyId": "$policies[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?metadata[customerId]=a81b9d89dec6&product=$products[1]"
    Then the response status should be "200"
    And the response body should be an array with 1 "user"

  @ee
  Scenario: Environment retrieves all isolated users for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "users"
    And the current account has 3 shared "users"
    And the current account has 3 global "users"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  @ee
  Scenario: Environment retrieves all shared users for their account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "users"
    And the current account has 3 shared "users"
    And the current account has 3 global "users"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "users"

  Scenario: Product retrieves all users
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 3 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: Product retrieves all users for their product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 3 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?product=$products[0]"
    Then the response status should be "200"
    And the response body should be an array with 1 "user"

  Scenario: Admin retrieves users filtered by status (active)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 7 "users"
    And the second "user" has the following attributes:
      """
      { "bannedAt": "$time.now" }
      """
    And the current account has 6 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[7]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[4]" }
      """
    And the third "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.2.days.ago",
        "createdAt": "$time.91.days.ago",
        "userId": "$users[5]"
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.91.days.ago",
        "createdAt": "$time.101.days.ago",
        "userId": "$users[3]"
      }
      """
    # NOTE(ezekg) Updating user created timestamps in reverse order,
    #             after license assignment.
    And the fifth "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the fourth "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the third "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=ACTIVE"
    Then the response status should be "200"
    And the response body should be an array with 5 "users"

  Scenario: Admin retrieves users filtered by status (inactive)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the second "user" has the following attributes:
      """
      { "bannedAt": "$time.now" }
      """
    And the third "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the fourth "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the current account has 6 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[7]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[4]" }
      """
    And the third "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.2.days.ago",
        "createdAt": "$time.91.days.ago",
        "userId": "$users[6]"
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.91.days.ago",
        "createdAt": "$time.101.days.ago",
        "userId": "$users[3]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=INACTIVE"
    Then the response status should be "200"
    And the response body should be an array with 2 "users"

  Scenario: Admin retrieves users filtered by status (banned)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the second "user" has the following attributes:
      """
      { "bannedAt": "$time.now" }
      """
    And the third "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the fourth "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the current account has 6 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[7]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[4]" }
      """
    And the third "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.2.days.ago",
        "createdAt": "$time.91.days.ago",
        "userId": "$users[6]"
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.91.days.ago",
        "createdAt": "$time.101.days.ago",
        "userId": "$users[3]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=BANNED"
    Then the response status should be "200"
    And the response body should be an array with 1 "user"

  Scenario: Admin retrieves users filtered by status (invalid)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 7 "users"
    And the first "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the second "user" has the following attributes:
      """
      { "bannedAt": "$time.now" }
      """
    And the third "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the fourth "user" has the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And the current account has 6 userless "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[7]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[4]" }
      """
    And the third "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.2.days.ago",
        "createdAt": "$time.91.days.ago",
        "userId": "$users[6]"
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "lastValidatedAt": "$time.91.days.ago",
        "createdAt": "$time.101.days.ago",
        "userId": "$users[3]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=INVALID"
    Then the response status should be "200"
    And the response body should be an array with 0 "users"

  Scenario: Product retrieves all users for their product (multiple licenses per-user)
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the second "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 4 "users"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]", "policyId": "$policies[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[1]" }
      """
    And the fifth "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[2]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?product=$products[0]"
    Then the response status should be "200"
    And the response body should be an array with 2 "users"

  Scenario: Product retrieves all users of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 3 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?product=$products[1]"
    Then the response status should be "200"
    And the response body should be an array with 1 "user"

  Scenario: Admin attempts to retrieve all users for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: Admin attempts to retrieve all users for another account via search
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 9 "users"
    And the fourth "user" has the following attributes:
      """
      {
        "metadata": {
          "foo": "bar"
        }
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?metadata[foo]=bar"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: License attempts to retrieve all users for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 5 "users"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all users for their account
    Given the current account is "test1"
    And the current account has 5 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "403"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all users for their group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 9 "users"
    And the third "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fifth "user" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "403"
