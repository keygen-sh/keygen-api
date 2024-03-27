@api/v1
Feature: Product platforms relationship

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
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "403"

  Scenario: Admin retrieves the platforms for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip        | zip      | macos    |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | Test-App-1.0.1.zip        | zip      | macos    |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | Test-App-1.1.0.zip        | zip      | macos    |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "200"
    And the response body should be an array with 2 "platforms"

  @ee
  Scenario: Environment retrieves the platforms for an isolated product
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
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.2.0-beta.1 | beta    |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip        | zip      | macos    | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip        | zip      | macos    | amd64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip        | zip      | macos    | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-1.2.0-beta.1.zip | zip      | win32    | x86   |
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 1 "platform"

  @ee
  Scenario: Environment retrieves the platforms for a mixed product
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code   | isolation_strategy |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | Global |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 |                                      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 |                                      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd |                                      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 |                                      | Test-App-1.0.0.zip        | zip      | macos    | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 |                                      | Test-App-1.0.1.zip        | zip      | macos    | amd64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd |                                      | Test-App-1.1.0.zip        | zip      | macos    | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-1.2.0-beta.1.zip | zip      | win32    | x86   |
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "platforms"

  Scenario: Product retrieves the platforms for a product
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
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "200"
    And the response body should be an array with 3 "platforms"

  Scenario: Admin retrieves a platform for a product
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
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms/$0"
    Then the response status should be "200"
    And the response body should be a "platform"

  Scenario: Product retrieves a platform for their product
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
    When I send a GET request to "/accounts/test1/products/$0/platforms/$0"
    Then the response status should be "200"
    And the response body should be a "platform"

  Scenario: Product retrieves the platforms of another product
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
    When I send a GET request to "/accounts/test1/products/$1/platforms"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the platforms for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for the first "release"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "200"
    And the response body should be an array with 1 "platform"

  Scenario: User attempts to retrieve the platforms for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for the first "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the platforms for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "200"
    And the response body should be an array with 1 "platform"

  Scenario: License attempts to retrieve the platforms for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the platforms for a product of another account
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
    When I send a GET request to "/accounts/test1/products/$0/platforms"
    Then the response status should be "401"
