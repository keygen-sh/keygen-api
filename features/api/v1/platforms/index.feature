@api/v1
Feature: List release platforms

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
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "403"

  Scenario: Admin retrieves their release platforms (all have associated releases)
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
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "platforms"

  Scenario: Admin retrieves their release platforms (some have associated releases)
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
      | release_id                           | filename                  | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip        | zip      | macos    |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And the current account has the following "platform" rows:
      | id                                   | name    | key     |
      | 1663f35c-f682-45f7-a7e3-757759dc7d0c | Android | android |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "platforms"

  Scenario: Product retrieves their release platforms
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
      | release_id                           | filename                        | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | Test-App-1.0.0.zip              | zip      | darwin   |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | Test-App-1.0.1.zip              | zip      | darwin   |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | Test-App-1.0.2.zip              | zip      | darwin   |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | Test-App-1.0.3.zip              | zip      | darwin   |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | Test-App-1.1.0.zip              | zip      | darwin   |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | Test-App-1.1.1.zip              | zip      | darwin   |
      | 19688446-f9a6-4b63-8e54-65aaf1eb35af | Test-App-1.1.2.zip              | zip      | darwin   |
      | 7385b023-c924-4cb9-896c-ddbcddd88c83 | Test-App-1.2.0.zip              | zip      | darwin   |
      | 42c5d79f-d968-4caa-9b40-05b3926154fe | Test-App-1.3.0.zip              | zip      | darwin   |
      | 2cf0b71b-c4a1-46d0-ab1e-fd324f7cc197 | Test-App-1.4.0-beta.1.zip       | zip      | darwin   |
      | 3a0d17fb-6277-4b26-8007-e27aeb8b3146 | Test-App-1.4.0-beta.2.zip       | zip      | darwin   |
      | ebafa75f-cdf1-4635-9378-bf1f43320e09 | Test-App-1.4.0-beta.3.zip       | zip      | darwin   |
      | 98e6104f-877f-41b7-a122-7698814de5dd | Test-App-1.4.0.zip              | zip      | darwin   |
      | fe372db5-66c4-4c99-91f5-88b29567462b | Test-App-1.5.0.zip              | zip      | darwin   |
      | d2fa75e4-6ed6-4a13-b0de-3888276a6a17 | Test-App-1.6.0.zip              | zip      | darwin   |
      | 591227c1-c448-4586-b5e6-41978a80040a | Test-App-1624653614.zip         | zip      | darwin   |
      | 19d24546-57d3-4c91-bb02-e8bffefe3380 | Test-App-1.7.0.zip              | zip      | darwin   |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-macOS-1624654615.zip   | zip      | darwin   |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-Windows-1624654615.zip | zip      | win32    |
      | 094016fa-8112-4b91-9fa6-17a7d59bb6e4 | Test-App-Linux-1624654615.zip   | zip      | linux    |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | Test-App-Android.apk            | apk      | android  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "platforms"

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
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"

  Scenario: User attempts to retrieve the platforms for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for an existing "release"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "platform"

  Scenario: User attempts to retrieve the platforms for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for an existing "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"

  Scenario: License attempts to retrieve the platforms for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "platform"

  Scenario: License attempts to retrieve the platforms for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"

  Scenario: Admin attempts to retrieve the platforms for a product of another account
    Given the current account is "test1"
    And the current account has the following "release" rows:
      | id                                   | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "401"

  Scenario: Anonymous attempts to retrieve the platforms for an account (LICENSED distribution strategy)
   Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"

  Scenario: Anonymous attempts to retrieve the platforms for an account (OPEN distribution strategy)
   Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "platform"

  Scenario: Anonymous attempts to retrieve the platforms for an account (CLOSED distribution strategy)
   Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"
