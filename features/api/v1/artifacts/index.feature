@api/v1
Feature: List release artifacts

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
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "403"

  Scenario: Admin retrieves all release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 7 "artifacts"

  Scenario: Admin retrieves all stable release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=stable"
    Then the response status should be "200"
    And the response body should be an array with 4 "artifacts"

  Scenario: Admin retrieves all beta release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=beta"
    Then the response status should be "200"
    And the response body should be an array with 7 "artifacts"

  Scenario: Admin retrieves all alpha release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1  | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0         | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=alpha"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  @ce
  Scenario: Environment retrieves their release artifacts (isolated)
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
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves their release artifacts (isolated)
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
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 10 "artifacts"
    And the response body should be an array of 10 "artifacts" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/bf20fe24-351d-47d0-b3c3-2c576a63d22f" },
          "data": { "type": "environments", "id": "bf20fe24-351d-47d0-b3c3-2c576a63d22f" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves their release artifacts (shared)
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
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 1 "artifact"
    And the response body should be an array of 1 "artifact" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/60e7f35f-5401-4cc2-abd3-999b2a758ee1" },
          "data": { "type": "environments", "id": "60e7f35f-5401-4cc2-abd3-999b2a758ee1" }
        }
      }
      """

  @ee
  Scenario: Environment retrieves their release artifacts (global)
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
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "401"

  Scenario: Product retrieves their release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version                    | channel  |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha    |
      | adf4ac18-e17c-46ec-b467-56762b2cd862 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable   |
      | 0f26a7db-3d15-4f78-b3d5-b13a2c916480 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable   |
      | 8b107e71-d926-4c99-a139-955dc77203be | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable   |
      | 349e6ef7-a24d-4aca-af1d-dba8aed3629f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable   |
      | f15405fb-9124-49fa-b7a4-8dfa6497c9e9 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.0                      | stable   |
      | 2d0a64cb-13d2-43b9-8669-f4e23765311b | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.1                      | stable   |
      | 2af8c310-ae1e-4da4-88cd-e06b63b1e353 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.2                      | stable   |
      | 359d4964-2e93-4590-8350-e83f00571918 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.2.0                      | stable   |
      | d584e9a7-c0a8-424c-b0ac-8efc0243df52 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.3.0                      | stable   |
      | 891cb839-f101-46ba-8b12-8eab05e7e9f5 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.1               | beta     |
      | 14839d41-9612-4bbf-8865-408d2f22a73e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.2               | beta     |
      | 95a32135-f349-4e12-919a-d421565e4656 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.3               | beta     |
      | e7f24b70-a7f1-4450-9dc1-bf0c4c51e65d | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0                      | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.5.0                      | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.6.0                      | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.7.0-dev+build.1624653614 | dev      |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.7.0                      | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1651683471 | dev      |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1651683478 | dev      |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1651683483 | dev      |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                        | filetype | platform |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   |
      | adf4ac18-e17c-46ec-b467-56762b2cd862 | Test-App-1.0.0.zip              | zip      | darwin   |
      | 0f26a7db-3d15-4f78-b3d5-b13a2c916480 | Test-App-1.0.1.zip              | zip      | darwin   |
      | 8b107e71-d926-4c99-a139-955dc77203be | Test-App-1.0.2.zip              | zip      | darwin   |
      | 349e6ef7-a24d-4aca-af1d-dba8aed3629f | Test-App-1.0.3.zip              | zip      | darwin   |
      | f15405fb-9124-49fa-b7a4-8dfa6497c9e9 | Test-App-1.1.0.zip              | zip      | darwin   |
      | 2d0a64cb-13d2-43b9-8669-f4e23765311b | Test-App-1.1.1.zip              | zip      | darwin   |
      | 2af8c310-ae1e-4da4-88cd-e06b63b1e353 | Test-App-1.1.2.zip              | zip      | darwin   |
      | 359d4964-2e93-4590-8350-e83f00571918 | Test-App-1.2.0.zip              | zip      | darwin   |
      | d584e9a7-c0a8-424c-b0ac-8efc0243df52 | Test-App-1.3.0.zip              | zip      | darwin   |
      | 891cb839-f101-46ba-8b12-8eab05e7e9f5 | Test-App-1.4.0-beta.1.zip       | zip      | darwin   |
      | 14839d41-9612-4bbf-8865-408d2f22a73e | Test-App-1.4.0-beta.2.zip       | zip      | darwin   |
      | 95a32135-f349-4e12-919a-d421565e4656 | Test-App-1.4.0-beta.3.zip       | zip      | darwin   |
      | e7f24b70-a7f1-4450-9dc1-bf0c4c51e65d | Test-App-1.4.0.zip              | zip      | darwin   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | Test-App-1.5.0.zip              | zip      | darwin   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | Test-App-1.6.0.zip              | zip      | darwin   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1624653614.zip         | zip      | darwin   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.7.0.zip              | zip      | darwin   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-macOS-1651683471.zip   | zip      | darwin   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-Windows-1651683478.zip | zip      | win32    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-Linux-1651683483.zip   | zip      | linux    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-Android.apk            | apk      | android  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=alpha"
    Then the response status should be "200"
    And the response body should be an array with 5 "artifacts"

  Scenario: Admin retrieves all artifacts by filetype
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    | arm64 |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    | arm64 |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    | arm64 |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    | amd64 |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    | x86   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    | x86   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | x86   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?filetype=zip"
    Then the response status should be "200"
    And the response body should be an array with 4 "artifacts"

  Scenario: Admin retrieves all artifacts by platform
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    | arm64 |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    | arm64 |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    | arm64 |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    | amd64 |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    | amd64 |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    | amd64 |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | x86   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?platform=macos"
    Then the response status should be "200"
    And the response body should be an array with 4 "artifacts"

  Scenario: Admin retrieves all artifacts by arch
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    | arm64 |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    | arm64 |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    | arm64 |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    | amd64 |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    | amd64 |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    | amd64 |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | x86   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?arch=amd64"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Admin retrieves all artifacts by platform and arch
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    | arm64 |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    | arm64 |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    | arm64 |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    | amd64 |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    | amd64 |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    | amd64 |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | x86   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?platform=macos&arch=amd64"
    Then the response status should be "200"
    And the response body should be an array with 1 "artifact"

  Scenario: Admin retrieves all artifacts by release
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    | arm64 |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    | arm64 |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    | arm64 |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    | amd64 |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    | x86   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    | x86   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | x86   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?release=0a027f00-0860-4fa7-bd37-5900c8866818"
    Then the response status should be "200"
    And the response body should be an array with 1 "artifact"

  Scenario: Read-only retrieves all artifacts by release
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    | arm64 |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    | arm64 |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    | arm64 |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    | amd64 |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    | x86   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    | x86   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | x86   |
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?release=0a027f00-0860-4fa7-bd37-5900c8866818"
    Then the response status should be "200"
    And the response body should be an array with 1 "artifact"

  Scenario: Product retrieves the artifacts of another product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.dmg    | dmg      | macos    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.zip    | zip      | win32    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array of 0 "artifacts"

  Scenario: User attempts to retrieve the artifacts for their products (licensed)
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "policy" for each "product"
    And the current account has 2 "licenses" for the first "policy"
    And the current account has 1 "license" for the second "policy"
    And the current account has 2 "releases" for each "product"
    And the current account has 2 "artifacts" for each "release"
    And the current account has 1 "user"
    And the first "license" belongs to the last "user"
    And the second "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array of 4 "artifacts"

  Scenario: User attempts to retrieve the artifacts for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "artifacts" for the last "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array of 0 "artifacts"

  Scenario: License attempts to retrieve the artifacts for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "releases" for the last "product"
    And the current account has 3 "artifacts" for existing "releases"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array of 3 "artifacts"

  Scenario: License attempts to retrieve the artifacts for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "artifacts" for existing "releases"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array of 0 "artifacts"

  Scenario: Admin attempts to retrieve the artifacts for a product of another account
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.dmg    | dmg      | macos    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.zip    | zip      | win32    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "401"

  Scenario: Anonymous attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 5 "artifacts"

  Scenario: License attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 8 "artifacts"

  Scenario: License attempts to retrieve all accessible releases (filtered)
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?product=$products[1]"
    Then the response status should be "200"
    And the response body should be an array with 5 "artifacts"

  Scenario: User attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 8 "artifacts"

  Scenario: User attempts to retrieve all accessible releases (filtered)
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts?product=$products[0]"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  # Draft releases
  Scenario: Anonymous retrieves artifacts for draft releases
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves artifacts for draft releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves artifacts for draft releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves artifacts for draft releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves artifacts for draft releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Product retrieves artifacts for draft releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Product retrieves artifacts for draft releases of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 draft "releases" for the second "product"
    And the current account has 1 "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Admin retrieves artifacts for draft releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  # Yanked releases
  Scenario: Anonymous retrieves artifacts for yanked releases
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves artifacts for yanked releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves artifacts for yanked releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves artifacts for yanked releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves artifacts for yanked releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Product retrieves artifacts for yanked releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Product retrieves artifacts for yanked releases of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 yanked "releases" for the second "product"
    And the current account has 1 "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Admin retrieves artifacts for yanked releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  # Waiting artifacts
  Scenario: Anonymous retrieves waiting artifacts
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 waiting "artifact" for each "release"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves waiting artifacts without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 waiting "artifact" for each "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves waiting artifacts with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 waiting "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves waiting artifacts without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 waiting "artifact" for each "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves waiting artifacts with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Product retrieves waiting artifacts
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 waiting "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Product retrieves waiting artifacts of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the second "product"
    And the current account has 1 waiting "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Admin retrieves waiting artifacts
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 waiting "artifact" for each "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  # Failed artifacts
  Scenario: Anonymous retrieves failed artifacts
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 failed "artifact" for each "release"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves failed artifacts without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 failed "artifact" for each "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves failed artifacts with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 failed "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves failed artifacts without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 failed "artifact" for each "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves failed artifacts with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Product retrieves failed artifacts
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 failed "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Product retrieves failed artifacts of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the second "product"
    And the current account has 1 failed "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Admin retrieves failed artifacts
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 failed "artifact" for each "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  # Yanked artifacts
  Scenario: Anonymous retrieves yanked artifacts
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 yanked "artifact" for each "release"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves yanked artifacts without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 yanked "artifact" for each "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: License retrieves yanked artifacts with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 yanked "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves yanked artifacts without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 yanked "artifact" for each "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: User retrieves yanked artifacts with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Product retrieves yanked artifacts
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 yanked "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: Product retrieves yanked artifacts of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the second "product"
    And the current account has 1 yanked "artifact" for each "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 0 "artifacts"

  Scenario: Admin retrieves yanked artifacts
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 yanked "artifact" for each "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: License retrieves their product artifacts with constraints (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "constraint" for the last "release"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 2 "artifacts"

  Scenario: License retrieves their product artifacts with constraints (some entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 2 "artifacts"

  Scenario: License retrieves their product artifacts with constraints (all entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"

  Scenario: User retrieves their product artifacts with constraints (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "constraint" for the last "release"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 2 "artifacts"

  Scenario: User retrieves their product artifacts with constraints (some entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 2 "licenses"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 2 "artifacts"

  Scenario: User retrieves their product artifacts with constraints (all entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 2 "licenses"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the response body should be an array with 3 "artifacts"
