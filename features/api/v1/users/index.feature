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
    And the current account has 15 "licenses" for existing "users" through "owner"
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
    And the current account has 15 "licenses" for existing "users" through "owner"
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
    And time is frozen at "2024-02-07T00:00:00.000Z"
    And the current account has the following "user" rows:
      | id                                   | email                                      | created_at               | banned_at                |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | new.user.active@keygen.example             | 2024-02-07T00:00:00.000Z |                          |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | old.user.inactive@keygen.example           | 2023-02-07T00:00:00.000Z |                          |
      | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | old.user.new.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | old.user.old.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | old.user.valid.license@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | 44dce69e-bb15-4915-9adc-074f8b57a61c | old.user.checkout.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | a04ac105-ec12-4dc9-89d0-06dd99124349 | old.user.checkin.license@keygen.example    | 2023-02-07T00:00:00.000Z |                          |
      | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | old.user.mixed.licenses@keygen.example     | 2023-02-07T00:00:00.000Z |                          |
      | be3ea9f0-e7ca-4eea-9326-a7658c247e5f | old.user.new.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | 4dface92-de40-4950-ab0e-f79e611884f5 | old.user.old.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | b2966243-fd44-4649-9724-a0ba1e5f4384 | old.user.valid.user.license@keygen.example | 2023-02-07T00:00:00.000Z |                          |
      | 5e360440-acd7-4c63-973e-5133b2ebfdbb | banned.user@keygen.example                 | 2024-02-07T00:00:00.000Z | 2024-01-07T00:00:00.000Z |
    And the current account has the following "license" rows:
      | id                                   | user_id                              | created_at               | last_validated_at        | last_check_out_at        | last_check_in_at         |
      | df0beed9-1ab2-4097-9558-cd0adddf321a | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | c29fc20f-ec09-4cf4-8145-f910109e5705 | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | af5c7d44-26bd-4bfd-9dcc-8aed721308ab | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | ee26deca-5688-451f-86bd-801291dd2d24 | 44dce69e-bb15-4915-9adc-074f8b57a61c | 2023-02-07T00:00:00.000Z |                          | 2024-02-07T00:00:00.000Z |                          |
      | e4304d3f-4d6c-4faf-86ee-0ddbb3324aa5 | a04ac105-ec12-4dc9-89d0-06dd99124349 | 2023-02-07T00:00:00.000Z |                          |                          | 2024-02-07T00:00:00.000Z |
      | 2022a17f-87e4-4b4c-a07b-e28b45f43d6a | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | ce5fc968-cff0-4b41-9f5d-cb42c330d01c | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | 12b570c9-1cbe-4b47-b60a-cc525e60ddab |                                      | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de |                                      | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 |                                      | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
    And the current account has the following "license_user" rows:
      | id                                   | license_id                           | user_id                              |
      | 85a3fc7e-dfb7-40d5-9420-9d1f342b2140 | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | be3ea9f0-e7ca-4eea-9326-a7658c247e5f |
      | 0bf8c414-8505-4e8e-9d5f-800c387906bc | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de | 4dface92-de40-4950-ab0e-f79e611884f5 |
      | bbd3becd-1abf-4a5c-860e-18b53d14d10a | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 | b2966243-fd44-4649-9724-a0ba1e5f4384 |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=ACTIVE"
    Then the response status should be "200"
    And the response body should be an array with 8 "users"
    And the response body should be an array with 8 "users" with the following attributes:
      """
      { "status": "ACTIVE" }
      """
    And time is unfrozen

  Scenario: Admin retrieves users filtered by status (inactive)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-02-07T00:00:00.000Z"
    And the current account has the following "user" rows:
      | id                                   | email                                      | created_at               | banned_at                |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | new.user.active@keygen.example             | 2024-02-07T00:00:00.000Z |                          |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | old.user.inactive@keygen.example           | 2023-02-07T00:00:00.000Z |                          |
      | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | old.user.new.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | old.user.old.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | old.user.valid.license@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | 44dce69e-bb15-4915-9adc-074f8b57a61c | old.user.checkout.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | a04ac105-ec12-4dc9-89d0-06dd99124349 | old.user.checkin.license@keygen.example    | 2023-02-07T00:00:00.000Z |                          |
      | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | old.user.mixed.licenses@keygen.example     | 2023-02-07T00:00:00.000Z |                          |
      | be3ea9f0-e7ca-4eea-9326-a7658c247e5f | old.user.new.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | 4dface92-de40-4950-ab0e-f79e611884f5 | old.user.old.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | b2966243-fd44-4649-9724-a0ba1e5f4384 | old.user.valid.user.license@keygen.example | 2023-02-07T00:00:00.000Z |                          |
      | 5e360440-acd7-4c63-973e-5133b2ebfdbb | banned.user@keygen.example                 | 2024-02-07T00:00:00.000Z | 2024-01-07T00:00:00.000Z |
    And the current account has the following "license" rows:
      | id                                   | user_id                              | created_at               | last_validated_at        | last_check_out_at        | last_check_in_at         |
      | df0beed9-1ab2-4097-9558-cd0adddf321a | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | c29fc20f-ec09-4cf4-8145-f910109e5705 | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | af5c7d44-26bd-4bfd-9dcc-8aed721308ab | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | ee26deca-5688-451f-86bd-801291dd2d24 | 44dce69e-bb15-4915-9adc-074f8b57a61c | 2023-02-07T00:00:00.000Z |                          | 2024-02-07T00:00:00.000Z |                          |
      | e4304d3f-4d6c-4faf-86ee-0ddbb3324aa5 | a04ac105-ec12-4dc9-89d0-06dd99124349 | 2023-02-07T00:00:00.000Z |                          |                          | 2024-02-07T00:00:00.000Z |
      | 2022a17f-87e4-4b4c-a07b-e28b45f43d6a | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | ce5fc968-cff0-4b41-9f5d-cb42c330d01c | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | 12b570c9-1cbe-4b47-b60a-cc525e60ddab |                                      | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de |                                      | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 |                                      | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
    And the current account has the following "license_user" rows:
      | id                                   | license_id                           | user_id                              |
      | 85a3fc7e-dfb7-40d5-9420-9d1f342b2140 | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | be3ea9f0-e7ca-4eea-9326-a7658c247e5f |
      | 0bf8c414-8505-4e8e-9d5f-800c387906bc | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de | 4dface92-de40-4950-ab0e-f79e611884f5 |
      | bbd3becd-1abf-4a5c-860e-18b53d14d10a | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 | b2966243-fd44-4649-9724-a0ba1e5f4384 |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=INACTIVE"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"
    And the response body should be an array with 3 "users" with the following attributes:
      """
      { "status": "INACTIVE" }
      """
    And time is unfrozen

  Scenario: Admin retrieves users filtered by status (banned)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-02-07T00:00:00.000Z"
    And the current account has the following "user" rows:
      | id                                   | email                                      | created_at               | banned_at                |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | new.user.active@keygen.example             | 2024-02-07T00:00:00.000Z |                          |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | old.user.inactive@keygen.example           | 2023-02-07T00:00:00.000Z |                          |
      | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | old.user.new.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | old.user.old.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | old.user.valid.license@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | 44dce69e-bb15-4915-9adc-074f8b57a61c | old.user.checkout.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | a04ac105-ec12-4dc9-89d0-06dd99124349 | old.user.checkin.license@keygen.example    | 2023-02-07T00:00:00.000Z |                          |
      | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | old.user.mixed.licenses@keygen.example     | 2023-02-07T00:00:00.000Z |                          |
      | be3ea9f0-e7ca-4eea-9326-a7658c247e5f | old.user.new.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | 4dface92-de40-4950-ab0e-f79e611884f5 | old.user.old.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | b2966243-fd44-4649-9724-a0ba1e5f4384 | old.user.valid.user.license@keygen.example | 2023-02-07T00:00:00.000Z |                          |
      | 5e360440-acd7-4c63-973e-5133b2ebfdbb | banned.user@keygen.example                 | 2024-02-07T00:00:00.000Z | 2024-01-07T00:00:00.000Z |
    And the current account has the following "license" rows:
      | id                                   | user_id                              | created_at               | last_validated_at        | last_check_out_at        | last_check_in_at         |
      | df0beed9-1ab2-4097-9558-cd0adddf321a | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | c29fc20f-ec09-4cf4-8145-f910109e5705 | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | af5c7d44-26bd-4bfd-9dcc-8aed721308ab | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | ee26deca-5688-451f-86bd-801291dd2d24 | 44dce69e-bb15-4915-9adc-074f8b57a61c | 2023-02-07T00:00:00.000Z |                          | 2024-02-07T00:00:00.000Z |                          |
      | e4304d3f-4d6c-4faf-86ee-0ddbb3324aa5 | a04ac105-ec12-4dc9-89d0-06dd99124349 | 2023-02-07T00:00:00.000Z |                          |                          | 2024-02-07T00:00:00.000Z |
      | 2022a17f-87e4-4b4c-a07b-e28b45f43d6a | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | ce5fc968-cff0-4b41-9f5d-cb42c330d01c | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | 12b570c9-1cbe-4b47-b60a-cc525e60ddab |                                      | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de |                                      | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 |                                      | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
    And the current account has the following "license_user" rows:
      | id                                   | license_id                           | user_id                              |
      | 85a3fc7e-dfb7-40d5-9420-9d1f342b2140 | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | be3ea9f0-e7ca-4eea-9326-a7658c247e5f |
      | 0bf8c414-8505-4e8e-9d5f-800c387906bc | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de | 4dface92-de40-4950-ab0e-f79e611884f5 |
      | bbd3becd-1abf-4a5c-860e-18b53d14d10a | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 | b2966243-fd44-4649-9724-a0ba1e5f4384 |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=BANNED"
    Then the response status should be "200"
    And the response body should be an array with 1 "user"
    And the response body should be an array with 1 "users" with the following attributes:
      """
      { "status": "BANNED" }
      """
    And time is unfrozen

  Scenario: Admin retrieves users filtered by status (invalid)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And time is frozen at "2024-02-07T00:00:00.000Z"
    And the current account has the following "user" rows:
      | id                                   | email                                      | created_at               | banned_at                |
      | d00998f9-d224-4ee7-ac4e-f1e5fe318ff7 | new.user.active@keygen.example             | 2024-02-07T00:00:00.000Z |                          |
      | 31e30cc1-d454-40dc-b4ae-93ad683ddf33 | old.user.inactive@keygen.example           | 2023-02-07T00:00:00.000Z |                          |
      | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | old.user.new.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | old.user.old.license@keygen.example        | 2023-02-07T00:00:00.000Z |                          |
      | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | old.user.valid.license@keygen.example      | 2023-02-07T00:00:00.000Z |                          |
      | 44dce69e-bb15-4915-9adc-074f8b57a61c | old.user.checkout.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | a04ac105-ec12-4dc9-89d0-06dd99124349 | old.user.checkin.license@keygen.example    | 2023-02-07T00:00:00.000Z |                          |
      | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | old.user.mixed.licenses@keygen.example     | 2023-02-07T00:00:00.000Z |                          |
      | be3ea9f0-e7ca-4eea-9326-a7658c247e5f | old.user.new.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | 4dface92-de40-4950-ab0e-f79e611884f5 | old.user.old.user.license@keygen.example   | 2023-02-07T00:00:00.000Z |                          |
      | b2966243-fd44-4649-9724-a0ba1e5f4384 | old.user.valid.user.license@keygen.example | 2023-02-07T00:00:00.000Z |                          |
      | 5e360440-acd7-4c63-973e-5133b2ebfdbb | banned.user@keygen.example                 | 2024-02-07T00:00:00.000Z | 2024-01-07T00:00:00.000Z |
    And the current account has the following "license" rows:
      | id                                   | user_id                              | created_at               | last_validated_at        | last_check_out_at        | last_check_in_at         |
      | df0beed9-1ab2-4097-9558-cd0adddf321a | 31e7d077-88ed-4808-bd4b-00b23fc35a57 | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | c29fc20f-ec09-4cf4-8145-f910109e5705 | 08c7f078-85d3-46cf-b34c-8dbcef0d30cd | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | af5c7d44-26bd-4bfd-9dcc-8aed721308ab | 2b8dcb3b-4518-4ffb-8512-b49d36dd7dd5 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | ee26deca-5688-451f-86bd-801291dd2d24 | 44dce69e-bb15-4915-9adc-074f8b57a61c | 2023-02-07T00:00:00.000Z |                          | 2024-02-07T00:00:00.000Z |                          |
      | e4304d3f-4d6c-4faf-86ee-0ddbb3324aa5 | a04ac105-ec12-4dc9-89d0-06dd99124349 | 2023-02-07T00:00:00.000Z |                          |                          | 2024-02-07T00:00:00.000Z |
      | 2022a17f-87e4-4b4c-a07b-e28b45f43d6a | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | ce5fc968-cff0-4b41-9f5d-cb42c330d01c | 6a0e6577-05eb-47d4-8498-a32d81f5c2b8 | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
      | 12b570c9-1cbe-4b47-b60a-cc525e60ddab |                                      | 2024-02-07T00:00:00.000Z |                          |                          |                          |
      | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de |                                      | 2023-02-07T00:00:00.000Z |                          |                          |                          |
      | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 |                                      | 2023-02-07T00:00:00.000Z | 2024-02-07T00:00:00.000Z |                          |                          |
    And the current account has the following "license_user" rows:
      | id                                   | license_id                           | user_id                              |
      | 85a3fc7e-dfb7-40d5-9420-9d1f342b2140 | 12b570c9-1cbe-4b47-b60a-cc525e60ddab | be3ea9f0-e7ca-4eea-9326-a7658c247e5f |
      | 0bf8c414-8505-4e8e-9d5f-800c387906bc | 5796eb0e-cae8-43b7-9fdc-d5a6bf6597de | 4dface92-de40-4950-ab0e-f79e611884f5 |
      | bbd3becd-1abf-4a5c-860e-18b53d14d10a | e5bdae6f-2f76-4b83-aa28-85a3321bbc95 | b2966243-fd44-4649-9724-a0ba1e5f4384 |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users?status=INVALID"
    Then the response status should be "200"
    And the response body should be an array with 0 "users"
    And time is unfrozen

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

  Scenario: License attempts to retrieve all associated users (without permission)
    Given the current account is "test1"
    And the current account has 5 "users"
    And the current account has 1 "license" for the second "user" as "owner"
    And the current account has 1 "license-user" for the last "license" and the third "user"
    And the current account has 1 "license-user" for the last "license" and the fourth "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "403"

  Scenario: License attempts to retrieve all associated users (with permission)
    Given the current account is "test1"
    And the current account has 5 "users"
    And the current account has 1 "license" for the second "user" as "owner"
    And the last "license" has the following permissions:
      """
      ["user.read"]
      """
    And the current account has 1 "license-user" for the last "license" and the third "user"
    And the current account has 1 "license-user" for the last "license" and the fourth "user"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: User attempts to retrieve all associated users (has teammates)
    Given the current account is "test1"
    And the current account has 5 "users"
    And the current account has 1 "license" for the second "user" as "owner"
    And the current account has 1 "license-user" for the last "license" and the third "user"
    And the current account has 1 "license-user" for the last "license" and the fourth "user"
    And I am the third user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 3 "users"

  Scenario: User attempts to retrieve all associated users (no teammates)
    Given the current account is "test1"
    And the current account has 5 "users"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users"
    Then the response status should be "200"
    And the response body should be an array with 1 "user"

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
    Then the response status should be "200"
    And the response body should be an array with 1 "user"
