@api/v1
Feature: Show package
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
    And the current account has 1 "package"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a package for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Developer retrieves a package for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Sales retrieves a package for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Support retrieves a package for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Read-only retrieves a package for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Admin retrieves an invalid package for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested release package 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin attempts to retrieve a package for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "packages"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Environment retrieves an isolated package
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "package"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "package"

  @ee
  Scenario: Environment retrieves a shared package
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "package"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "package"

  @ee
  Scenario: Environment retrieves a global package
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "package"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Product retrieves itself
    Given the current account is "test1"
    And the current account has 3 "packages"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Product attempts to retrieve another package
    Given the current account is "test1"
    And the current account has 3 "packages"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$1"
    Then the response status should be "404"

  Scenario: License attempts to retrieve their package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve a package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "packages"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$1"
    Then the response status should be "404"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve the package for their license (license owner)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the first "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve the package for their license (license user)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve a package
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "packages"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/$1"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to retrieve a licensed package
    Given the current account is "test1"
    And the current account has 2 licensed "package"
    When I send a GET request to "/accounts/test1/packages/$1"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to retrieve a closed package
    Given the current account is "test1"
    And the current account has 2 closed "package"
    When I send a GET request to "/accounts/test1/packages/$1"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to retrieve an open package
    Given the current account is "test1"
    And the current account has 2 open "package"
    When I send a GET request to "/accounts/test1/packages/$1"
    Then the response status should be "200"
    And the response body should be a "package"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
