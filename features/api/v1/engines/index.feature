@api/v1
Feature: List release engines
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
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "403"

  Scenario: Admin retrieves their release engines (all have associated packages)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 | pypi   |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c |                                      | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                     | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | test-1.0.0-py3-none-any.wh   | wh       |          |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | test-1.0.1-py3-none-any.wh   | wh       |          |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | test-1.1.0-py3-none-any.wh   | wh       |          |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | test-1.2.0b1-py3-none-any.wh | wh       |          |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | test-1.0.0b1-py3-none-any.wh | wh       |          |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | test-1.0.0b2-py3-none-any.wh | wh       |          |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | test.1.0.0.tar.gz            | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Admin retrieves their release engines (none have associated packages)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "engine" rows:
      | id                                   | name  | key  |
      | 1663f35c-f682-45f7-a7e3-757759dc7d0c | PyPI  | pypi |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 |        |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 1.0.0        | stable  |
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
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 0 "engines"

  @ce
  Scenario: Environment retrieves their release engines (isolated)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "package" rows:
      | id                                   | environment_id                       | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 | pypi   |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                     | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0-py3-none-any.wh   | wh       |          |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.1-py3-none-any.wh   | wh       |          |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.1.0-py3-none-any.wh   | wh       |          |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.2.0b1-py3-none-any.wh | wh       |          |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b1-py3-none-any.wh | wh       |          |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b2-py3-none-any.wh | wh       |          |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | test.1.0.0.tar.gz            | tar.gz   | linux    |
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves their release engines (isolated)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "package" rows:
      | id                                   | environment_id                       | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 | pypi   |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                     | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0-py3-none-any.wh   | wh       |          |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.1-py3-none-any.wh   | wh       |          |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.1.0-py3-none-any.wh   | wh       |          |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.2.0b1-py3-none-any.wh | wh       |          |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b1-py3-none-any.wh | wh       |          |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b2-py3-none-any.wh | wh       |          |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | test.1.0.0.tar.gz            | tar.gz   | linux    |
    And I am the first environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  @ee
  Scenario: Environment retrieves their release engines (shared)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "package" rows:
      | id                                   | environment_id                       | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 | pypi   |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                     | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0-py3-none-any.wh   | wh       |          |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.1-py3-none-any.wh   | wh       |          |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.1.0-py3-none-any.wh   | wh       |          |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.2.0b1-py3-none-any.wh | wh       |          |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b1-py3-none-any.wh | wh       |          |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b2-py3-none-any.wh | wh       |          |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | test.1.0.0.tar.gz            | tar.gz   | linux    |
    And I am the second environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 0 "engines"

  @ee
  Scenario: Environment retrieves their release engines (global)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test 2 |
    And the current account has the following "package" rows:
      | id                                   | environment_id                       | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 | pypi   |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                     | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0-py3-none-any.wh   | wh       |          |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.1-py3-none-any.wh   | wh       |          |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.1.0-py3-none-any.wh   | wh       |          |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.2.0b1-py3-none-any.wh | wh       |          |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b1-py3-none-any.wh | wh       |          |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | test-1.0.0b2-py3-none-any.wh | wh       |          |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | test.1.0.0.tar.gz            | tar.gz   | linux    |
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "401"

  Scenario: Product retrieves their release engines
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 | pypi   |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c |                                      | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                     | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | test-1.0.0-py3-none-any.wh   | wh       |          |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | test-1.0.1-py3-none-any.wh   | wh       |          |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | test-1.1.0-py3-none-any.wh   | wh       |          |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | test-1.2.0b1-py3-none-any.wh | wh       |          |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | test-1.0.0b1-py3-none-any.wh | wh       |          |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | test-1.0.0b2-py3-none-any.wh | wh       |          |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | test.1.0.0.tar.gz            | tar.gz   | linux    |
    And I am the first product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"

  Scenario: Product retrieves the engines of another product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      | engine |
      | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 6198261a-48b5-4445-a045-9fed4afc7735 | Package 1 | package1 | pypi   |
      | 0012fa4c-0f1b-45c2-a13c-ad717b3e8673 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Package 2 | package2 |        |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | 6198261a-48b5-4445-a045-9fed4afc7735 | 818c5625-7c4d-4e4b-9bdf-e4d1475db721 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c |                                      | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                     | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | test-1.0.0-py3-none-any.wh   | wh       |          |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | test-1.0.1-py3-none-any.wh   | wh       |          |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | test-1.1.0-py3-none-any.wh   | wh       |          |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | test-1.2.0b1-py3-none-any.wh | wh       |          |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | test-1.0.0b1-py3-none-any.wh | wh       |          |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | test-1.0.0b2-py3-none-any.wh | wh       |          |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | test.1.0.0.tar.gz            | tar.gz   | linux    |
    And I am the second product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 0 "engines"

  Scenario: User attempts to retrieve the engines for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the last "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 1 "engine"

  Scenario: User attempts to retrieve the engines for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the last "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 0 "engines"

  Scenario: License attempts to retrieve the engines for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the last "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 1 "engine"

  Scenario: License attempts to retrieve the engines for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the last "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 0 "engines"

  Scenario: Anonymous attempts to retrieve the engines for an account (LICENSED distribution strategy)
   Given the current account is "test1"
    And the current account has 1 licensed "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the last "product"
    And the last "package" belongs to the last "engine"
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 0 "engines"

  Scenario: Anonymous attempts to retrieve the engines for an account (OPEN distribution strategy)
   Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the last "product"
    And the last "package" belongs to the last "engine"
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 1 "engine"

  Scenario: Anonymous lists all engines (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has 1 closed "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the last "product"
    And the last "package" belongs to the last "engine"
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 0 "engines"

  @ee
  Scenario: Isolated license attempts to retrieve the engines for an account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 "engine"
    And the current account has 1 isolated "package" for the last "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 1 "engine"

  @ee
  Scenario: Shared license attempts to retrieve the engines for an account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "product"
    And the current account has 1 "engine"
    And the current account has 1 shared "package" for the last "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/engines"
    Then the response status should be "200"
    And the response body should be an array of 1 "engine"

  @ee
  Scenario: Admin retrieves their isolated release engines
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 shared "product"
    And the current account has 1 global "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the first "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 isolated "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Admin retrieves their shared release engines
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 shared "product"
    And the current account has 1 global "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the second "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 shared "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent1/engines"
    Then the response status should be "200"
    And the response body should be an array with 1 "engine"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  @ee
  Scenario: Admin retrieves their global release engines
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 shared "product"
    And the current account has 1 global "product"
    And the current account has 1 "engine"
    And the current account has 1 "package" for the first "product"
    And the last "package" belongs to the last "engine"
    And the current account has 1 global "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a GET request to "/accounts/ent1/engines"
    Then the response status should be "200"
    And the response body should be an array with 0 "engines"
