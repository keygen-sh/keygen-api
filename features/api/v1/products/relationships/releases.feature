@api/v1
Feature: Product releases relationship
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
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "403"

  Scenario: Admin retrieves the releases for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"
    And the first "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[2]/artifacts" }
        }
      }
      """

  Scenario: Admin retrieves the releases for a product (v1.1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    And I use API version "1.1"
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"
    And the first "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[2]/artifacts" }
        }
      }
      """

  Scenario: Admin retrieves the releases for a product (v1.0)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"
    And the first "release" should have the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[2]/artifact" },
          "data": null
        }
      }
      """

  @ee
  Scenario: Environment retrieves the releases for an isolated product
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-beta.1 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip        | zip      | macos    | x86   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip        | zip      | macos    | x86   |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip        | zip      | macos    | x86   |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-1.0.0.zip        | zip      | win32    | amd64 |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-2.0.0-beta.1.zip | zip      | win32    | amd64 |
    And I am the first environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"
    And the response body should be an array of 3 "releases" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/bf20fe24-351d-47d0-b3c3-2c576a63d22f" },
          "data": { "type": "environments", "id": "bf20fe24-351d-47d0-b3c3-2c576a63d22f" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves the releases for a shared product
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-beta.1 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip        | zip      | macos    | x86   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip        | zip      | macos    | x86   |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip        | zip      | macos    | x86   |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-1.0.0.zip        | zip      | win32    | amd64 |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-2.0.0-beta.1.zip | zip      | win32    | amd64 |
    And I am the second environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/releases?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"
    And the response body should be an array of 2 "releases" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/60e7f35f-5401-4cc2-abd3-999b2a758ee1" },
          "data": { "type": "environments", "id": "60e7f35f-5401-4cc2-abd3-999b2a758ee1" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves the releases for a mixed product
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c |                                      | Mixed   |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe |                                      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-beta.1 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip        | zip      | macos    | x86   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip        | zip      | macos    | x86   |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip        | zip      | macos    | x86   |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe |                                      | Test-App-1.0.0.zip        | zip      | win32    | amd64 |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-2.0.0-beta.1.zip | zip      | win32    | amd64 |
    And I am the second environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/releases?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"
    And the response body should be an array of 1 "release" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/60e7f35f-5401-4cc2-abd3-999b2a758ee1" },
          "data": { "type": "environments", "id": "60e7f35f-5401-4cc2-abd3-999b2a758ee1" }
        }
      }
      """
    And the response body should be an array of 1 "release" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """

  Scenario: Product retrieves the releases for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Admin retrieves a release for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release"

  Scenario: Product retrieves a release for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases/$0"
    Then the response status should be "200"
    And the response body should be a "release"

  Scenario: Product retrieves the releases of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/releases"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the releases for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"

  Scenario: License attempts to retrieve the releases for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license"
    And the current account has 3 "licenses" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the releases for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"

  Scenario: User attempts to retrieve the releases for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "licenses" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the releases for a product of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "401"
