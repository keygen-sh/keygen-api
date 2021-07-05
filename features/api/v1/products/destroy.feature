@api/v1
Feature: Delete product

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
    And the current account has 1 "product"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their products (2FA disabled, without confirmation)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$2"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "confirmation is required",
        "code": "CONFIRMATION_REQUIRED",
        "source": {
          "pointer": "/meta/confirmation"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their products (2FA disabled, with invalid confirmation)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$2" with the following:
      """
      {
        "meta": {
          "confirmation": "Invalid Name"
        }
      }
      """
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "confirmation must match",
        "code": "CONFIRMATION_INVALID",
        "source": {
          "pointer": "/meta/confirmation"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their products (2FA disabled, with valid confirmation)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$2" with the following:
      """
      {
        "meta": {
          "confirmation": "$products[2].name"
        }
      }
      """
    Then the response status should be "204"
    And the current account should have 2 "products"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their products (2FA enabled, without OTP)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    And I have 2FA enabled
    When I send a DELETE request to "/accounts/test1/products/$2"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "second factor is required",
        "code": "OTP_REQUIRED",
        "source": {
          "pointer": "/meta/otp"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their products (2FA enabled, with invalid OTP)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    And I have 2FA enabled
    When I send a DELETE request to "/accounts/test1/products/$2" with the following:
      """
      {
        "meta": {
          "otp": "000000"
        }
      }
      """
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "second factor must be valid",
        "code": "OTP_INVALID",
        "source": {
          "pointer": "/meta/otp"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their products (2FA enabled, with valid OTP)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    And I have 2FA enabled
    When I send a DELETE request to "/accounts/test1/products/$2" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "204"
    And the current account should have 2 "products"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete a product for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 4 "webhook-endpoints"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the current account should have 3 "products"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes one of their products
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$1" with the following:
      """
      {
        "meta": {
          "confirmation": "$products[1].name"
        }
      }
      """
    Then the response status should be "204"
    And the current account should have 2 "products"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales attempts to delete one of their products
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$2"
    Then the response status should be "403"
    And the current account should have 3 "products"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Support attempts to delete one of their products
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$2"
    Then the response status should be "403"
    And the current account should have 3 "products"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes itself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$0"
    Then the response status should be "403"
    And the current account should have 2 "products"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete another product for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$1"
    Then the response status should be "403"
    And the current account should have 3 "products"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete their product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/products/$0"
    Then the response status should be "403"

  Scenario: User attempts to delete a one of their products
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a DELETE request to "/accounts/test1/products/$0"
    Then the response status should be "403"

  Scenario: Anonymous attempts to delete a product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "products"
    When I send a DELETE request to "/accounts/test1/products/$1"
    Then the response status should be "401"
