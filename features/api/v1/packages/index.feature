@api/v1
Feature: List packages
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
    And the current account has 2 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "403"

  Scenario: Admin retrieves all packages for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"

  Scenario: Admin retrieves all packages for the PyPI engine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 pypi "packages"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?engine=pypi"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"

  Scenario: Admin retrieves all packages for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 "packages" for each "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?product=$products[1]"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"

  Scenario: Developer retrieves all packages for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 2 "packages"

  Scenario: Sales retrieves all packages for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 2 "packages"

  Scenario: Support retrieves all packages for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 5 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 5 "packages"

  Scenario: Read-only retrieves all packages for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 5 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 5 "packages"

  Scenario: Admin retrieves a paginated list of packages
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "packages"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/packages?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/packages?page[number]=2&page[size]=5",
        "last": "/v1/accounts/test1/packages?page[number]=4&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """

  Scenario: Admin retrieves a paginated list of packages with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of packages with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of packages with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all packages without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 10 "packages"

  Scenario: Admin retrieves all packages with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "packages"

  Scenario: Admin retrieves all packages with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "packages"

  Scenario: Admin retrieves all packages with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all packages with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?limit=-10"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all packages for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ce
  Scenario: Admin retrieves all isolated packages
    Given the current account is "test1"
    And the current account has 3 isolated "packages"
    And the current account has 3 shared "packages"
    And the current account has 3 global "packages"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?environment=isolated"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves all isolated packages
    Given the current account is "test1"
    And the current account has 3 isolated "packages"
    And the current account has 3 shared "packages"
    And the current account has 3 global "packages"
    And I am the first environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"
    And the response body should be an array of 3 "packages" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves all shared packages
    Given the current account is "test1"
    And the current account has 3 isolated "packages"
    And the current account has 3 shared "packages"
    And the current account has 3 global "packages"
    And I am the second environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "packages"
    And the response body should be an array of 3 "packages" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[1]" },
          "data": { "type": "environments", "id": "$environments[1]" }
        }
      }
      """
    And the response body should be an array of 3 "packages" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """

    Scenario: Product attempts to retrieve its packages
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to retrieve all packages
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 0 "packages"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their packages
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve all packages
    Given the current account is "test1"
    And the current account has 3 "packages"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 0 "packages"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their packages
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve all packages
    Given the current account is "test1"
    And the current account has 5 "packages"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 0 "packages"
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to retrieve all packages
    Given the current account is "test1"
    And the current account has 3 licensed "packages"
    And the current account has 3 closed "packages"
    And the current account has 3 open "packages"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"
    And sidekiq should have 1 "request-log" job
