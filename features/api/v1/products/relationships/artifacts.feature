@api/v1
Feature: Product artifacts relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  # List artifacts
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

  Scenario: Admin retrieves all artifacts for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta    |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 591227c1-c448-4586-b5e6-41978a80040a | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 6 "artifacts"

  Scenario: Admin retrieves stable artifacts for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta    |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | status   |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | Test-App-1.0.0.dmg        | dmg      | macos    | UPLOADED |
      | 591227c1-c448-4586-b5e6-41978a80040a | Test-App-1.0.1.dmg        | dmg      | macos    | UPLOADED |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | Test-App-1.1.0.dmg        | dmg      | macos    | WAITING  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | FAILED   |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | Test-App.1.0.0-beta.1.exe | exe      | win32    | WAITING  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | Test-App.1.0.0-beta.2.exe | exe      | win32    | WAITING  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | UPLOADED |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts?channel=stable"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Admin retrieves the failed artifacts for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta    |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | status   |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | Test-App-1.0.0.dmg        | dmg      | macos    | UPLOADED |
      | 591227c1-c448-4586-b5e6-41978a80040a | Test-App-1.0.1.dmg        | dmg      | macos    | UPLOADED |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | Test-App-1.1.0.dmg        | dmg      | macos    | WAITING  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | FAILED   |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | Test-App.1.0.0-beta.1.exe | exe      | win32    | WAITING  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | Test-App.1.0.0-beta.2.exe | exe      | win32    | WAITING  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | UPLOADED |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts?status=failed"
    Then the response status should be "200"
    And the response body should be an array with 1 "artifact"

  Scenario: Admin retrieves the waiting artifacts for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta    |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | status   |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | Test-App-1.0.0.dmg        | dmg      | macos    | UPLOADED |
      | 591227c1-c448-4586-b5e6-41978a80040a | Test-App-1.0.1.dmg        | dmg      | macos    | UPLOADED |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | Test-App-1.1.0.dmg        | dmg      | macos    | WAITING  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | FAILED   |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | Test-App.1.0.0-beta.1.exe | exe      | win32    | WAITING  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | Test-App.1.0.0-beta.2.exe | exe      | win32    | WAITING  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | UPLOADED |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts?status=WAITING"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Admin retrieves the uploaded artifacts for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta    |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | status   |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | Test-App-1.0.0.dmg        | dmg      | macos    | UPLOADED |
      | 591227c1-c448-4586-b5e6-41978a80040a | Test-App-1.0.1.dmg        | dmg      | macos    | UPLOADED |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | Test-App-1.1.0.dmg        | dmg      | macos    | WAITING  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | FAILED   |
      | 06807d5b-e38e-4db0-bbd7-eb2bdc499979 | Test-App.1.0.0-beta.1.exe | exe      | win32    | WAITING  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | Test-App.1.0.0-beta.2.exe | exe      | win32    | WAITING  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | UPLOADED |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts?status=uPlOaDeD"
    Then the response status should be "200"
    And the response body should be an array with 2 "artifacts"

  @ee
  Scenario: Environment retrieves the artifacts for an isolated product
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
    When I send a GET request to "/accounts/test1/products/$0/artifacts?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"
    And the response body should be an array of 3 "artifacts" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/bf20fe24-351d-47d0-b3c3-2c576a63d22f" },
          "data": { "type": "environments", "id": "bf20fe24-351d-47d0-b3c3-2c576a63d22f" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves the artifacts for a shared product
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
    When I send a GET request to "/accounts/test1/products/$1/artifacts?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "artifacts"
    And the response body should be an array of 2 "artifacts" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/60e7f35f-5401-4cc2-abd3-999b2a758ee1" },
          "data": { "type": "environments", "id": "60e7f35f-5401-4cc2-abd3-999b2a758ee1" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves the artifacts for a mixed product
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
    When I send a GET request to "/accounts/test1/products/$1/artifacts?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "artifacts"
    And the response body should be an array of 1 "artifact" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/60e7f35f-5401-4cc2-abd3-999b2a758ee1" },
          "data": { "type": "environments", "id": "60e7f35f-5401-4cc2-abd3-999b2a758ee1" }
        }
      }
      """
    And the response body should be an array of 1 "artifact" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """

  Scenario: Product retrieves the artifacts for their product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Product retrieves the artifacts of another product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/artifacts"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the artifacts for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: User attempts to retrieve the artifacts for a product (licensed, expired)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      {
        "expiry": "$time.1.week.ago",
        "userId": "$users[1]"
      }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the artifacts for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for an existing "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the artifacts for their product (valid)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: License attempts to retrieve the artifacts for their product (expired)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.week.ago" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the artifacts for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the artifacts for a product of another account
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "401"

  Scenario: Anonymous retrieves the artifacts for an open release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 licensed "releases" for the last "product"
    And the current account has 3 closed "releases" for the last "product"
    And the current account has 3 open "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "401"

  # Show artifact
  Scenario: Admin retrieves an artifact for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"
    And the response body should be an "artifact"

  Scenario: Developer retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Sales retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Support retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Read-only retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Admin retrieves an invalid artifact for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested release artifact 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  @ee
  Scenario: Environment retrieves an artifact for an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0?environment=isolated"
    Then the response status should be "303"
    And the response body should be an "artifact"

  Scenario: Product retrieves an artifact for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"
    And the response body should be an "artifact"

  Scenario: Product retrieves an artifact for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the first "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the first "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact with a license for it
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And the current account has 1 "user"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the last "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves an artifact of a different product
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the first "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for the first "release"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Anonymous retrieves an artifact
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the first "release"
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "401"

  Scenario: Admin attempts to retrieve an artifact for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

