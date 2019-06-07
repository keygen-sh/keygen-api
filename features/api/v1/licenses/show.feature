@api/v1
Feature: Show license

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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a valid accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: application/json
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"
    And the response should contain the following raw headers:
      """
      Content-Type: application/json
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a wildcard accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: application/json, text/plain, */*
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with a mixed accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: text/plain, application/vnd.api+json, application/json
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.api+json
      """
    And the JSON response should be a "license"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account with an unsupported accept header
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I send the following raw headers:
      """
      Accept: text/plain, text/html
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unsupported accept header: text/plain, text/html"
      }
      """

  Scenario: Admin retrieves a license for their account that has a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/user" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """

  Scenario: Admin retrieves a license for their account that doesn't have a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/user" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves a license for their account by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "key": "a-license-key" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/a-license-key"
    Then the response status should be "200"
    And the JSON response should be a "license"

  Scenario: Admin retrieves a license for their account by UUID key that matches another account license by ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "id": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "id": "a9ad138d-a603-4309-85d0-764585bba99b",
        "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/977f1752-d6a9-4669-a6af-b039154ec40f"
    Then the response status should be "200"
    And the JSON response should be a "license" with the id "a9ad138d-a603-4309-85d0-764585bba99b"
    And the JSON response should be a "license" with the following attributes:
      """
      {
        "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """

  Scenario: Admin retrieves a license for their account by UUID that matches another account license by UUID key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "key": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "key": "a9ad138d-a603-4309-85d0-764585bba99b",
        "id": "977f1752-d6a9-4669-a6af-b039154ec40f"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/977f1752-d6a9-4669-a6af-b039154ec40f"
    Then the response status should be "200"
    And the JSON response should be a "license" with the id "977f1752-d6a9-4669-a6af-b039154ec40f"
    And the JSON response should be a "license" with the following attributes:
      """
      {
        "key": "a9ad138d-a603-4309-85d0-764585bba99b"
      }
      """

  Scenario: Admin retrieves an invalid license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested license 'invalid' was not found"
      }
      """

  Scenario: Admin retrieves a legacy encrypted license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 legacy encrypted "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license" without a key attribute

  Scenario: Admin attempts to retrieve a legacy encrypted license for their account by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 legacy encrypted "licenses"
    And the first "license" has the following attributes:
      # Hashed 'a-license-key' using Bcrypt
      """
      { "key": "$2a$10$UcRHfYqf3DayM7iF/44pqOm0X9/UoEBcBRv3O4xFhJbXDIamHVBe." }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/a-license-key"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested license 'a-license-key' was not found"
      }
      """

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_ENCRYPT
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_ENCRYPT"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_SIGN"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_PKCS1_PSS_SIGN
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a license for their account by key using scheme RSA_2048_JWT_RS256
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license" using "RSA_2048_JWT_RS256"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a license for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    And the current product has 1 "license"
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"

  Scenario: Product attempts to retrieve a license for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a license for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: License retrieves their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"

  Scenario: License attempts to retrieve another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$1"
    Then the response status should be "403"

  # Scenario: Admin requests an license with an invalid URI
  #   Given I am an admin of account "test1"
  #   And the current account is "test1"
  #   And the current account has 1 "webhook-endpoint"
  #   And I use an authentication token
  #   When I send a GET request to "/accounts/test1/licenses/[invalid-url]"
  #   Then the response status should be "400"
  #   And the JSON response should be an array of 1 error
  #   And the first error should have the following properties:
  #     """
  #     {
  #       "title": "Bad request",
  #       "detail": "The request could not be completed because the URI was invalid (please ensure non-URL safe chars are properly encoded)",
  #       "code": "URI_INVALID"
  #     }
  #     """
  #   And sidekiq should have 0 "webhook" jobs
  #   And sidekiq should have 0 "metric" jobs
  #   And sidekiq should have 1 "request-log" job
