@api/v1
Feature: Release constraints relationship

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "403"

  # Retrieval
  Scenario: Admin retrieves the constraints for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "200"
    And the response body should be an array with 3 "constraints"

  @ee
  Scenario: Environment retrieves the constraints for a shared release
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "release"
    And the current account has 3 shared "release-entitlement-constraints" for each "release"
    Given I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 3 "constraints"

  Scenario: Product retrieves the constraints for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "release-entitlement-constraints" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "200"
    And the response body should be an array with 3 "constraints"

  Scenario: Admin retrieves an constraints for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "200"
    And the response body should be a "constraint"

  Scenario: Product retrieves an constraints for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "200"
    And the response body should be a "constraint"

  Scenario: Product retrieves the constraints for a release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the constraints for a release of a different product
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the constraints for a release of their product
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "200"
    And the response body should be an array with 3 "constraints"

  Scenario: User attempts to retrieve the constraints for a release they don't have a license for
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the constraints for a release they do have a license for (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "200"
    And the response body should be an array with 3 "constraints"

  Scenario: User attempts to retrieve the constraints for a release they do have a license for (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "200"
    And the response body should be an array with 3 "constraints"

  Scenario: Admin attempts to retrieve the constraints for a release of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "401"

  Scenario: License attempts to retrieve a constraint for a release of their product (has entitlements)
    Given the current account is "test1"
    And the current account has 1 "entitlement"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "200"
    And the response body should be a "constraint"

  Scenario: License attempts to retrieve a constraint for a release of their product (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "entitlement"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "404"

  Scenario: License attempts to retrieve a constraint for a product release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "release-entitlement-constraints" for each "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "404"

  Scenario: User attempts to retrieve a constraint for a release they do have a license for (license owner, has entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "entitlement"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "200"
    And the response body should be a "constraint"

  Scenario: User attempts to retrieve a constraint for a release they do have a license for (license user, has entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "entitlement"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "200"
    And the response body should be a "constraint"

  Scenario: User attempts to retrieve a constraint for a release they do have a license for (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "entitlement"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "404"

  Scenario: User attempts to retrieve a constraint for a release they don't have a license for
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "release-entitlement-constraints" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "404"

  # Attachment
  Scenario: Admin attaches constraints to a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[1]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[2]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "200"
    And the response body should be an array of 3 "constraints"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attaches constraints to a release when the constraint already exists
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "entitlement"
    And the current account has 1 "release"
    And the current account has 1 "release-entitlement-constraints" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "already exists",
        "source": {
          "pointer": "/data/relationships/entitlement"
        },
        "code": "ENTITLEMENT_TAKEN"
      }
      """

  Scenario: Admin attempts to attach constraints to a release with an invalid entitlement ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[1]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "f5bcf743-52a3-4318-b35c-044fb201d70e" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "source": {
          "pointer": "/data/relationships/entitlement"
        },
        "code": "ENTITLEMENT_NOT_FOUND"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to attach constraints to a release with an invalid parameter
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "entitlements"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[1]", "bad": "param" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/1/relationships/entitlement/data/bad"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to attach an constraint to a release for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoint"
    And the current account has 1 "entitlement"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches isolated constraints to an isolated release
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 4 isolated "entitlements"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints?environment=isolated" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[2]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 2 "constraints"
    And the response body should be an array of 2 "constraints" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared constraints to an isolated release
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 4 shared "entitlements"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints?environment=isolated" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[2]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (a record's environment is not compatible with the current environment)"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment attaches shared constraints to a shared release
    Given the current account is "test1"
    And the current account has 2 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 2 shared "entitlements"
    And the current account has 1 global "entitlements"
    And the current account has 1 shared "release"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints?environment=shared" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[2]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 2 "constraints"
    And the response body should be an array of 2 "constraints" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attaches constraints to a release
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoint"
    And the current account has 4 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[2]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "200"
    And the response body should be an array with 2 "constraints"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to attach constraints to a release it doesn't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "entitlements"
    And the current account has 2 "products"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          },
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[1]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to attach constraints to a release
    Given the current account is "test1"
    And the current account has 2 "entitlements"
    And the current account has 1 "products"
    And the current account has 1 "release" for existing "products"
    And the current account has 1 "policy" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to attach constraints to a release
    Given the current account is "test1"
    And the current account has 2 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          {
            "type": "constraint",
            "relationships": {
              "entitlement": {
                "data": { "type": "entitlement", "id": "$entitlements[0]" }
              }
            }
          }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  # Detachment
  Scenario: Admin detaches constraints from a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" },
          { "type": "constraint", "id": "$constraints[1]" },
          { "type": "constraint", "id": "$constraints[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And the current account should have 0 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to detach constraints from a release with an invalid constraint ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" },
          { "type": "constraint", "id": "$constraints[1]" },
          { "type": "constraint", "id": "f40913d3-a786-407f-8dd6-94664b95ade8" }
        ]
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "cannot detach constraint 'f40913d3-a786-407f-8dd6-94664b95ade8' (constraint is not attached)",
        "source": {
          "pointer": "/data/2"
        }
      }
      """
    And the current account should have 3 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to detach an constraint from a release for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And the current account has 1 "release-entitlement-constraint" for existing "releases"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" }
        ]
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches isolated constraints from an isolated release
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "release"
    And the current account has 3 isolated "release-entitlement-constraints" for each "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" },
          { "type": "constraint", "id": "$constraints[1]" },
          { "type": "constraint", "id": "$constraints[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And the current account should have 0 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches shared constraints from a shared release
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "release"
    And the current account has 3 shared "release-entitlement-constraints" for each "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" },
          { "type": "constraint", "id": "$constraints[1]" },
          { "type": "constraint", "id": "$constraints[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 0 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches shared constraints from a global release
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "release"
    And the current account has 2 shared "release-entitlement-constraints" for each "release"
    And the current account has 1 global "release-entitlement-constraints" for each "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" },
          { "type": "constraint", "id": "$constraints[1]" }
        ]
      }
      """
    Then the response status should be "204"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 1 "release-entitlement-constraint"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment detaches global constraints from a global release
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "release"
    And the current account has 3 global "release-entitlement-constraints" for each "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[2]" }
        ]
      }
      """
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 3 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product detaches constraints from a release
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 4 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" },
          { "type": "constraint", "id": "$constraints[2]" }
        ]
      }
      """
    Then the response status should be "204"
    And the current account should have 2 "release-entitlement-constraints"
    And the current account should have 4 "entitlements"
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to detach constraints from a release it doesn't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 2 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" }
        ]
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to detach constraints from a release
    Given the current account is "test1"
    And the current account has 4 "entitlements"
    And the current account has 1 "products"
    And the current account has 1 "release" for existing "products"
    And the current account has 1 "policy" for existing "products"
    And the current account has 1 "license" for existing "policies"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[3]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[3]", "releaseId": "$releases[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to detach constraints from a release
    Given the current account is "test1"
    And the current account has 4 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[3]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[3]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/constraints" with the following:
      """
      {
        "data": [
          { "type": "constraint", "id": "$constraints[0]" }
        ]
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
