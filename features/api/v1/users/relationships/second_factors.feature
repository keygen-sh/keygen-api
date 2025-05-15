@api/v1
Feature: Manage second factors for user

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
    When I send a GET request to "/accounts/test1/users/$0/second-factors"
    Then the response status should be "403"

  # Second factor index
  Scenario: Admin lists second factors while having 2FA disabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 1 "second-factor"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin lists second factors while having 2FA enabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 1 "second-factor"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin lists second factors while having no second factor
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I do not have 2FA
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 0 "second-factors"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin lists a user's second factors and the user has 2FA disabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the first "user" has 2FA disabled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 1 "second-factor"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin lists a user's second factors and the user has 2FA enabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the first "user" has 2FA enabled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 1 "second-factor"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin lists a user's second factors and the user has no second factors
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the first "user" does not have 2FA
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 0 "second-factors"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User lists second factors while having 2FA disabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 1 "second-factors"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User lists second factors while having 2FA enabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 1 "second-factors"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User lists second factors while having no second factor
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I do not have 2FA
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "200"
    And the response body should be an array with 0 "second-factors"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User lists an admin's second factors
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the first "admin" has 2FA enabled
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment lists an isolated admin's second factors
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "admin"
    And the last "admin" has 2FA enabled
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment lists an isolated user's second factors
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "user"
    And the last "user" has 2FA enabled
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product lists an admin's second factors
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the first "admin" has 2FA enabled
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors"
    Then the response status should be "404"

  Scenario: Product lists a user's second factors
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" has 2FA enabled
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Second factor show
  Scenario: Admin retrieves a second factor while having 2FA disabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors/$0"
    Then the response status should be "200"
    And the response body should be a "second-factor" with the following attributes:
      """
      { "enabled": false }
      """
    And the response body should be a "second-factor" with a "secret" attribute
    And the response body should be a "second-factor" with a "uri" attribute
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves a second factor while having 2FA enabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors/$0"
    Then the response status should be "200"
    And the response body should be a "second-factor" with the following attributes:
      """
      { "enabled": true }
      """
    And the response body should be a "second-factor" without a "secret" attribute
    And the response body should be a "second-factor" without a "uri" attribute
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User retrieves a second factor while having 2FA disabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors/$0"
    Then the response status should be "200"
    And the response body should be a "second-factor" with the following attributes:
      """
      { "enabled": false }
      """
    And the response body should be a "second-factor" with a uri
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User retrieves a second factor while having 2FA enabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors/$0"
    Then the response status should be "200"
    And the response body should be a "second-factor" with the following attributes:
      """
      { "enabled": true }
      """
    And the response body should be a "second-factor" without a "uri" attribute
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment retrieve a shared user's second factor
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "user"
    And the last "user" has 2FA enabled
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors/$0?environment=shared"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product retrieve a user's second factor
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" has 2FA enabled
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$1/second-factors/$0"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Second factor creation
  Scenario: Admin creates a second factor while having no other second factor and providing a correct password
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I do not have 2FA
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "password": "password"
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a second factor while having no other second factor and providing a correct password
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I do not have 2FA
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/second-factors" with the following:
      """
      {
        "meta": {
          "password": "password"
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a second factor for an isolated user with no other second factor and provides a correct password
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "user"
    And the last "user" does not have 2FA
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/users/$1/second-factors" with the following:
      """
      {
        "meta": {
          "password": "password"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates a second factor for a user with no other second factor and provides a correct password
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" does not have 2FA
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$1/second-factors" with the following:
      """
      {
        "meta": {
          "password": "password"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a second factor while having no other second factor and providing an incorrect password
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I do not have 2FA
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "password": "h4x0r"
        }
      }
      """
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
       "title": "Unauthorized",
        "detail": "password must be valid",
        "code": "PASSWORD_INVALID",
        "source": {
          "pointer": "/meta/password"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a second factor while having 2FA disabled and providing a correct password
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "password": "password"
        }
      }
      """
    Then the response status should be "409"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a second factor while having 2FA disabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
       "title": "Unauthorized",
        "detail": "password must be valid",
        "code": "PASSWORD_INVALID",
        "source": {
          "pointer": "/meta/password"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a second factor while having 2FA enabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "409"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a second factor while having 2FA enabled and providing a correct password
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "password": "password"
        }
      }
      """
    Then the response status should be "401"
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

  Scenario: Admin creates a second factor while having 2FA enabled and providing an incorrect password
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "password": "h4x0r"
        }
      }
      """
    Then the response status should be "401"
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

  Scenario: Admin creates a second factor while having 2FA enabled and providing an incorrect OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a POST request to "/accounts/test1/users/$0/second-factors" with the following:
      """
      {
        "meta": {
          "otp": "000000"
        }
      }
      """
    Then the response status should be "401"
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

  # Second factor enable
  Scenario: Admin enables a second factor while having 2FA disabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factors",
          "attributes": {
            "enabled": true
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin enables a second factor while having 2FA enabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factor",
          "attributes": {
            "enabled": true
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin enables a second factor while having 2FA disabled and providing an incorrect OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factor",
          "attributes": {
            "enabled": true
          }
        },
        "meta": {
          "otp": "000000"
        }
      }
      """
    Then the response status should be "401"
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

  Scenario: Admin enables a second factor while having 2FA disabled and without an OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second_factor",
          "attributes": {
            "enabled": true
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "pointer": "/meta"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

   Scenario: User enables a second factor while having 2FA disabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factors",
          "attributes": {
            "enabled": true
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to enable a shared user's second factor
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "user"
    And the last "user" has 2FA disabled
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second_factor",
          "attributes": {
            "enabled": true
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to enable a user's second factor
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" has 2FA disabled
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second_factor",
          "attributes": {
            "enabled": true
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Second factor disable
  Scenario: Admin disables a second factor while having 2FA disabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "secondFactor",
          "attributes": {
            "enabled": true
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin disables a second factor while having 2FA enabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factor",
          "attributes": {
            "enabled": false
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin disables a second factor while having 2FA enabled and providing an incorrect OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factor",
          "attributes": {
            "enabled": false
          }
        },
        "meta": {
          "otp": "000000"
        }
      }
      """
    Then the response status should be "401"
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

  Scenario: Admin disables a second factor while having 2FA enabled and without an OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factor",
          "attributes": {
            "enabled": false
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "pointer": "/meta"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User disables a second factor while having 2FA enabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second-factors",
          "attributes": {
            "enabled": false
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to disable a shared user's second factor
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "user"
    And the last "user" has 2FA enabled
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second_factor",
          "attributes": {
            "enabled": false
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to disable a user's second factor
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" has 2FA enabled
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "data": {
          "type": "second_factor",
          "attributes": {
            "enabled": false
          }
        },
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  # Second factor deletion
  Scenario: Admin deletes a second factor while having 2FA enabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes a second factor while having 2FA disabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA disabled
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$0/second-factors/$0"
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes a second factor while having 2FA enabled and providing an incorrect OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$0/second-factors/$0" with the following:
      """
      {
        "meta": {
          "otp": "000000"
        }
      }
      """
    Then the response status should be "401"
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

  Scenario: User deletes a second factor while having 2FA enabled and providing a correct OTP
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attempts to delete a shared user's second factor
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "user"
    And the first "user" has 2FA enabled
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$1/second-factors/$0?environment=shared" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to delete a user's second factor
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the first "user" has 2FA enabled
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/users/$1/second-factors/$0" with the following:
      """
      {
        "meta": {
          "otp": "$otp"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
