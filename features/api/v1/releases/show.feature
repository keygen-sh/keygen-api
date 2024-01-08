@api/v1
Feature: Show release
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
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a release for their account by version
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the last "release" has the following attributes:
      """
      { "version": "1.0.0-beta.1" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0-beta.1"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[2]/artifacts" }
        }
      }
      """

  Scenario: Admin retrieves a release for their account by ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for the first "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifacts" }
        }
      }
      """

  Scenario: Admin retrieves a release for their account by ID (v1.1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for the first "release"
    And I use an authentication token
    And I use API version "1.1"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifacts" }
        }
      }
      """

  Scenario: Admin retrieves a published release for their account by ID (v1.0)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for the first "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifact" },
          "data": { "type": "artifacts", "id": "$artifacts[0]" }
        }
      }
      """

  Scenario: Admin retrieves a draft release for their account by ID (v1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifact" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves a release without a package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "package": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/package" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves a release with a package
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 packaged "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "package": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/package" },
          "data": { "type": "packages", "id": "$packages[0]" }
        }
      }
      """

  Scenario: Admin retrieves a draft release for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has the following attributes:
      """
      { "status": "DRAFT" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release" with the status "DRAFT"

  Scenario: Admin retrieves a published release for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has the following attributes:
      """
      { "status": "PUBLISHED" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release" with the status "PUBLISHED"

  Scenario: Admin retrieves a yanked release for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has the following attributes:
      """
      { "status": "YANKED" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release" with the status "YANKED"

  Scenario: License retrieves a release with a conflicting version (open/licensed)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name         | distribution_strategy |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Freemium App | OPEN                  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Premium App  | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0   | stable  |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "54a44eaf-6a83-4bb4-b3c1-17600dfdd77c"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/f14ef993-f821-44c9-b2af-62e27f37f8db/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.0" }
      """

  Scenario: License retrieves a release with a conflicting version (open/licensed, with product qualifier)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name         | distribution_strategy |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Freemium App | OPEN                  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Premium App  | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0   | stable  |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0?product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6198261a-48b5-4445-a045-9fed4afc7735"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/aa067117-948f-46e8-977f-6998ad366a97/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.0" }
      """

  Scenario: Developer retrieves a release for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Sales retrieves a release for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Support retrieves a release for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Read-only retrieves a release for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves an invalid release for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested release 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  @ee
  Scenario: Environment retrieves a release for their shared product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And the current product has 1 "release"
    When I send a GET request to "/accounts/test1/releases/$0?environment=shared"
    Then the response status should be "200"
    And the response body should be a "release"

  Scenario: Product retrieves a release for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And I am a product of account "test1"
    And I use an authentication token
    And the current product has 1 "release"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release"

  Scenario: Product retrieves a release for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a release without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a release with a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: License retrieves a release of a different product
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  # Licensed distribution strategy
  Scenario: Anonymous retrieves a LICENSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a LICENSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a LICENSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: License retrieves an LICENSED release with an expired license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "release" has the following attributes:
      """
      { "createdAt": "$time.3.months.ago" }
      """
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: License retrieves an LICENSED release with an expiry outside window
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.week.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "403"

  Scenario: User retrieves a LICENSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a LICENSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: User retrieves a LICENSED release with multiple licenses for it (mixed validity)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 3 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.year.ago" }
      """
    And the third "license" has the following attributes:
      """
      { "suspended": true }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 3 "licenses" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: User retrieves a LICENSED release with multiple licenses for it (all invalid)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 3 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.year.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": "$time.3.days.ago" }
      """
    And the third "license" has the following attributes:
      """
      { "suspended": true }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 3 "licenses" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (license expiry falls outside of access window)"
      }
      """

  Scenario: User retrieves a LICENSED release with multiple licenses for it (all valid)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 3 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 3 "licenses" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a LICENSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a LICENSED release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves a LICENSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the first "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  # Open distribution strategy
  Scenario: Anonymous retrieves an OPEN release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: License retrieves an OPEN release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: License retrieves an OPEN release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: License retrieves an OPEN release with an expired license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: User retrieves an OPEN release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: User retrieves an OPEN release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Product retrieves an OPEN release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Product retrieves an OPEN release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves an OPEN release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  # Closed distribution strategy
  Scenario: Anonymous retrieves a CLOSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the first "product"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a CLOSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a CLOSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a CLOSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a CLOSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Product retrieves a CLOSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the first "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a CLOSED release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves a CLOSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the first "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Admin attempts to retrieve a release for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  # Draft releases
  Scenario: Anonymous retrieves a draft release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a draft release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a draft release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a draft release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a draft release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Product retrieves a draft release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a draft release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 draft "release" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves a draft release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  # Yanked releases
  Scenario: Anonymous retrieves a yanked release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a yanked release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: License retrieves a yanked release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a yanked release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: User retrieves a yanked release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license" as "owner"
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Product retrieves a yanked release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a yanked release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 yanked "release" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves a yanked release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0"
    Then the response status should be "200"
