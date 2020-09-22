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
    And the JSON response should be an array with 1 "second-factor"
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
    And the JSON response should be an array with 1 "second-factor"
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
    And the JSON response should be an array with 0 "second-factors"
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
    And the JSON response should be a "second-factor" with the following attributes:
      """
      { "enabled": false }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves a second factor while having 2FA disabled
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I have 2FA enabled
    And I use an authentication token
    When I send a GET request to "/accounts/test1/users/$0/second-factors/$0"
    Then the response status should be "200"
    And the JSON response should be a "second-factor" with the following attributes:
      """
      { "enabled": true }
      """
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