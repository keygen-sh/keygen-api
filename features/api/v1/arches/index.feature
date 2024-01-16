@api/v1
Feature: List release arches
  Background:
    Given the following "plan" rows exist:
      | id                                   | name       |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Standard 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1      |
    Given the following "account" rows exist:
      | name   | slug  | plan_id                              |
      | Test 1 | test1 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Test 2 | test2 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Ent 1  | ent1  | 44c7918c-80ab-4a13-a831-a2c46cda85c6 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "403"

  Scenario: Admin retrieves their release arches (all have associated releases)
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
      | release_id                           | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip        | zip      | macos    | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | Test-App-1.0.1.zip        | zip      | macos    | amd64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | Test-App-1.1.0.zip        | zip      | macos    | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | Test-App-1.2.0-beta.1.zip | zip      | macos    | amd64 |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | Test-App.1.0.0-beta.1.exe | exe      | win32    | arm64 |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | Test-App.1.0.0-beta.2.exe | exe      | win32    | arm64 |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | 386   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array with 3 "arches"

  Scenario: Admin retrieves their release arches (some have associated releases)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip        | zip      | macos    | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | Test-App.1.0.0-beta.1.exe | exe      | win32    | arm64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | 386   |
    And the current account has the following "arch" rows:
      | id                                   | name | key |
      | 1663f35c-f682-45f7-a7e3-757759dc7d0c | ARM  | arm |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array with 3 "arches"

  @ce
  Scenario: Environment retrieves their release arches (isolated)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version                    | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | dev     |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                        | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip              | zip      | darwin   | arm64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip              | zip      | darwin   | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.2.zip              | zip      | darwin   | arm64 |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.3.zip              | zip      | darwin   | amd64 |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip              | zip      | darwin   | arm64 |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.1.zip              | zip      | darwin   | amd64 |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.2.zip              | zip      | darwin   | arm64 |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.2.0.zip              | zip      | darwin   | amd64 |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.3.0.zip              | zip      | darwin   | arm64 |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.1.zip       | zip      | darwin   | amd64 |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.2.zip       | zip      | darwin   | arm64 |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.3.zip       | zip      | darwin   | amd64 |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0.zip              | zip      | darwin   | arm64 |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.5.0.zip              | zip      | darwin   | amd64 |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.6.0.zip              | zip      | darwin   | arm64 |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1624653614.zip         | zip      | darwin   | amd64 |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.7.0.zip              | zip      | darwin   | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-macOS-1624654615.zip   | zip      | darwin   | amd64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Windows-1624654615.zip | zip      | win32    | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Linux-1624654615.zip   | zip      | linux    | 386   |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-Android.apk            | apk      | android  | arm   |
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves their release arches (isolated)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version                    | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | dev     |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                        | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip              | zip      | darwin   | arm64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip              | zip      | darwin   | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.2.zip              | zip      | darwin   | arm64 |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.3.zip              | zip      | darwin   | amd64 |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip              | zip      | darwin   | arm64 |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.1.zip              | zip      | darwin   | amd64 |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.2.zip              | zip      | darwin   | arm64 |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.2.0.zip              | zip      | darwin   | amd64 |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.3.0.zip              | zip      | darwin   | arm64 |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.1.zip       | zip      | darwin   | amd64 |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.2.zip       | zip      | darwin   | arm64 |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.3.zip       | zip      | darwin   | amd64 |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0.zip              | zip      | darwin   | arm64 |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.5.0.zip              | zip      | darwin   | amd64 |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.6.0.zip              | zip      | darwin   | arm64 |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1624653614.zip         | zip      | darwin   | amd64 |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.7.0.zip              | zip      | darwin   | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-macOS-1624654615.zip   | zip      | darwin   | amd64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Windows-1624654615.zip | zip      | win32    | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Linux-1624654615.zip   | zip      | linux    | 386   |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-Android.apk            | apk      | android  | arm   |
    And I am the first environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array with 3 "arches"

  @ee
  Scenario: Environment retrieves their release arches (shared)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version                    | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | dev     |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                        | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip              | zip      | darwin   | arm64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip              | zip      | darwin   | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.2.zip              | zip      | darwin   | arm64 |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.3.zip              | zip      | darwin   | amd64 |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip              | zip      | darwin   | arm64 |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.1.zip              | zip      | darwin   | amd64 |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.2.zip              | zip      | darwin   | arm64 |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.2.0.zip              | zip      | darwin   | amd64 |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.3.0.zip              | zip      | darwin   | arm64 |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.1.zip       | zip      | darwin   | amd64 |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.2.zip       | zip      | darwin   | arm64 |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.3.zip       | zip      | darwin   | amd64 |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0.zip              | zip      | darwin   | arm64 |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.5.0.zip              | zip      | darwin   | amd64 |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.6.0.zip              | zip      | darwin   | arm64 |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1624653614.zip         | zip      | darwin   | amd64 |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.7.0.zip              | zip      | darwin   | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-macOS-1624654615.zip   | zip      | darwin   | amd64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Windows-1624654615.zip | zip      | win32    | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Linux-1624654615.zip   | zip      | linux    | 386   |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-Android.apk            | apk      | android  | arm   |
    And I am the second environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array with 1 "arch"

  @ee
  Scenario: Environment retrieves their release arches (global)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version                    | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | dev     |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                        | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip              | zip      | darwin   | arm64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip              | zip      | darwin   | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.2.zip              | zip      | darwin   | arm64 |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.3.zip              | zip      | darwin   | amd64 |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip              | zip      | darwin   | arm64 |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.1.zip              | zip      | darwin   | amd64 |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.2.zip              | zip      | darwin   | arm64 |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.2.0.zip              | zip      | darwin   | amd64 |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.3.0.zip              | zip      | darwin   | arm64 |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.1.zip       | zip      | darwin   | amd64 |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.2.zip       | zip      | darwin   | arm64 |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0-beta.3.zip       | zip      | darwin   | amd64 |
      | 98e6104f-877f-41b7-a122-7698814de5dd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.4.0.zip              | zip      | darwin   | arm64 |
      | fe372db5-66c4-4c99-91f5-88b29567462b | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.5.0.zip              | zip      | darwin   | amd64 |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.6.0.zip              | zip      | darwin   | arm64 |
      | 591227c1-c448-4586-b5e6-41978a80040a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1624653614.zip         | zip      | darwin   | amd64 |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.7.0.zip              | zip      | darwin   | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-macOS-1624654615.zip   | zip      | darwin   | amd64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Windows-1624654615.zip | zip      | win32    | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-Linux-1624654615.zip   | zip      | linux    | 386   |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-Android.apk            | apk      | android  | arm   |
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "401"

  Scenario: Product retrieves their release arches
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version                    | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | 98e6104f-877f-41b7-a122-7698814de5dd | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | fe372db5-66c4-4c99-91f5-88b29567462b | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | 591227c1-c448-4586-b5e6-41978a80040a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | dev     |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                        | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | Test-App-1.0.0.zip              | zip      | darwin   | arm64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | Test-App-1.0.1.zip              | zip      | darwin   | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | Test-App-1.0.2.zip              | zip      | darwin   | arm64 |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | Test-App-1.0.3.zip              | zip      | darwin   | amd64 |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | Test-App-1.1.0.zip              | zip      | darwin   | arm64 |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | Test-App-1.1.1.zip              | zip      | darwin   | amd64 |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | Test-App-1.1.2.zip              | zip      | darwin   | arm64 |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | Test-App-1.2.0.zip              | zip      | darwin   | amd64 |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | Test-App-1.3.0.zip              | zip      | darwin   | arm64 |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | Test-App-1.4.0-beta.1.zip       | zip      | darwin   | amd64 |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | Test-App-1.4.0-beta.2.zip       | zip      | darwin   | arm64 |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | Test-App-1.4.0-beta.3.zip       | zip      | darwin   | amd64 |
      | 98e6104f-877f-41b7-a122-7698814de5dd | Test-App-1.4.0.zip              | zip      | darwin   | arm64 |
      | fe372db5-66c4-4c99-91f5-88b29567462b | Test-App-1.5.0.zip              | zip      | darwin   | amd64 |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | Test-App-1.6.0.zip              | zip      | darwin   | arm64 |
      | 591227c1-c448-4586-b5e6-41978a80040a | Test-App-1624653614.zip         | zip      | darwin   | amd64 |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | Test-App-1.7.0.zip              | zip      | darwin   | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-macOS-1624654615.zip   | zip      | darwin   | amd64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-Windows-1624654615.zip | zip      | win32    | arm64 |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-Linux-1624654615.zip   | zip      | linux    | 386   |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | Test-App-Android.apk            | apk      | android  | arm   |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array with 3 "arches"

  Scenario: Product retrieves the arches of another product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform | arch |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    | x86  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    | x86  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    | x86  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 0 "arches"

  Scenario: User attempts to retrieve the arches for their license (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 1 "arch"

  Scenario: User attempts to retrieve the arches for their license (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for an existing "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 1 "arch"

  Scenario: User attempts to retrieve their arches (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for an existing "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 0 "arches"

  Scenario: License attempts to retrieve the arches for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 1 "arch"

  Scenario: License attempts to retrieve the arches for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 0 "arches"

  Scenario: Admin attempts to retrieve the arches for a product of another account
    Given the current account is "test1"
    And the current account has the following "release" rows:
      | id                                   | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform | arch |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    | x86  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    | x86  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    | x86  |
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "401"

  Scenario: Anonymous attempts to retrieve the arches for an account (LICENSED distribution strategy)
   Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 0 "arches"

  Scenario: Anonymous attempts to retrieve the arches for an account (OPEN distribution strategy)
   Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 1 "arch"

  Scenario: Anonymous attempts to retrieve the arches for an account (CLOSED distribution strategy)
   Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 0 "arches"

  @ee
  Scenario: Isolated license attempts to retrieve the arches for an account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "releases" for the last "product"
    And the current account has 3 amd64 "artifacts" for each "release"
    And the current account has 2 arm64 "artifacts" for each "release"
    And the current account has 1 x86 "artifacts" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 3 "arches"

  @ee
  Scenario: Shared license attempts to retrieve the arches for an account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "releases" for the last "product"
    And the current account has 3 amd64 "artifacts" for each "release"
    And the current account has 2 arm64 "artifacts" for each "release"
    And the current account has 1 x86 "artifacts" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/arches"
    Then the response status should be "200"
    And the response body should be an array of 3 "arches"

  @ee
  Scenario: Admin retrieves their isolated release arches
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 shared "product"
    And the current account has 1 global "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "release" for the third "product"
    And the current account has 3 amd64 "artifacts" for the first "release"
    And the current account has 3 amd64 "artifacts" for the last "release"
    And the current account has 2 arm64 "artifacts" for the last "release"
    And the current account has 1 x86 "artifacts" for the second "release"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent1/arches"
    Then the response status should be "200"
    And the response body should be an array with 1 "arch"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Admin retrieves their shared release arches
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 shared "product"
    And the current account has 1 global "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "release" for the third "product"
    And the current account has 3 amd64 "artifacts" for the first "release"
    And the current account has 3 amd64 "artifacts" for the last "release"
    And the current account has 2 arm64 "artifacts" for the last "release"
    And the current account has 1 x86 "artifacts" for the second "release"
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent1/arches"
    Then the response status should be "200"
    And the response body should be an array with 3 "arches"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  @ee
  Scenario: Admin retrieves their global release arches
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 shared "product"
    And the current account has 1 global "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "release" for the third "product"
    And the current account has 3 amd64 "artifacts" for the first "release"
    And the current account has 3 amd64 "artifacts" for the last "release"
    And the current account has 2 arm64 "artifacts" for the last "release"
    And the current account has 1 x86 "artifacts" for the second "release"
    And the current account has 1 global "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a GET request to "/accounts/ent1/arches"
    Then the response status should be "200"
    And the response body should be an array with 2 "arches"
