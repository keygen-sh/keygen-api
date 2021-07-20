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

  Scenario: Admin retrieves the constraints for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "constraints"

  Scenario: Product retrieves the constraints for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "constraints"

  Scenario: Admin retrieves an constraints for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "200"
    And the JSON response should be a "constraint"

  Scenario: Product retrieves an constraints for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "200"
    And the JSON response should be a "constraint"

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
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the constraints for a release they don't have a license for
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the constraints for a release they do have a license for
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the constraints for a release of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints"
    Then the response status should be "401"

  Scenario: License attempts to retrieve a constraint for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "403"

  Scenario: User attempts to retrieve a constraint for a release they do have a license for
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/constraints/$0"
    Then the response status should be "403"

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
    And the JSON response should be an array of 3 "constraints"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
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
        "code": "ENTITLEMENT_BLANK"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
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
    And sidekiq should have 0 "metric" jobs
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
    And the JSON response should be an array with 2 "constraints"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
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
    And sidekiq should have 0 "metric" jobs
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to attach constraints to a release
    Given the current account is "test1"
    And the current account has 2 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "metric" job
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
        "detail": "constraint 'f40913d3-a786-407f-8dd6-94664b95ade8' relationship not found",
        "source": {
          "pointer": "/data/2"
        }
      }
      """
    And the current account should have 3 "release-entitlement-constraints"
    And the current account should have 3 "entitlements"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
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
    And sidekiq should have 0 "metric" jobs
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
    And sidekiq should have 1 "metric" job
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to detach constraints from a release
    Given the current account is "test1"
    And the current account has 1 "products"
    And the current account has 1 "release" for existing "products"
    And the current account has 4 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for existing "products"
    And the current account has 1 "license" for existing "policies"
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to detach constraints from a release
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 2 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    And I am a user of account "test1"
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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
