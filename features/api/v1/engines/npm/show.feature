@api/v1
Feature: npm package metadata
  Background:
    Given the following "accounts" exist:
      | id                                   | slug  | name   |
      | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | test1 | Test 1 |
      | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | test2 | Test 2 |
    And the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code    |
      | 1740e334-9d88-43c8-8b2e-38fd98f153d2 | INSIDER |
    And the current account has the following "product" rows:
      | id                                   | code  | name   | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | test1 | Test 1 | LICENSED              |
      | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | test2 | Test 2 | OPEN                  |
      | 6727d2a2-626c-4270-880c-3f7f378ea37a | test3 | Test 3 | CLOSED                |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | engine | key       | created_at               | updated_at               |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 6198261a-48b5-4445-a045-9fed4afc7735 | npm    | foo       | 2024-10-01T01:23:45.000Z | 2024-10-01T01:23:45.000Z |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 6198261a-48b5-4445-a045-9fed4afc7735 | npm    | @test/bar | 2024-10-02T01:23:45.000Z | 2024-10-02T01:23:45.000Z |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | npm    | baz       | 2024-10-03T01:23:45.000Z | 2024-10-03T01:23:45.000Z |
      | 2277f3e5-3a1b-4ae8-854a-85cbbe60d677 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | npm    | @test/baz | 2024-10-04T01:23:45.000Z | 2024-10-04T01:23:45.000Z |
      | cd46b4d3-60ab-43e9-b19d-87a9faf13adc | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | npm    | qux       | 2024-10-05T01:23:45.000Z | 2024-10-05T01:23:45.000Z |
      | 9baf459d-1bfe-429e-884e-926597b1d32f | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | npm    | @test/qux | 2024-10-06T01:23:45.000Z | 2024-10-06T01:23:45.000Z |
      | 5666d47e-936e-4d48-8dd7-382d32462b4e | 6198261a-48b5-4445-a045-9fed4afc7735 | raw    | quxx      | 2024-10-07T01:23:45.000Z | 2024-10-07T01:23:45.000Z |
      | 3d771f82-a0ed-48fd-914a-f5ecda9b4044 | 6727d2a2-626c-4270-880c-3f7f378ea37a | npm    | corge     | 2024-10-08T01:23:45.000Z | 2024-10-08T01:23:45.000Z |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel  | tag    | status    | entitlements |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0        | stable   |        | PUBLISHED |              |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.1        | stable   | latest | PUBLISHED |              |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0        | stable   |        | PUBLISHED | INSIDER      |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.1 | beta     |        | PUBLISHED |              |
      | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.2 | beta     | beta   | PUBLISHED |              |
      | 56f66b77-f447-4300-828b-5cf92e457376 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.3 | beta     |        | DRAFT     |              |
      | 0b5bb946-7346-448b-90a0-e8bbc02570e2 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | 7b113ac2-ae81-406a-b44e-f356126e2faa | 1.0.0        | stable   |        | YANKED    |              |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | 7b113ac2-ae81-406a-b44e-f356126e2faa | 2.0.0        | stable   |        | PUBLISHED |              |
      | 00c9c981-8a75-494b-9207-71a829665729 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | cd46b4d3-60ab-43e9-b19d-87a9faf13adc | 1.0.0        | stable   |        | PUBLISHED |              |
      | e00475de-edcc-4571-adec-5ef1b91ddb85 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | cd46b4d3-60ab-43e9-b19d-87a9faf13adc | 1.1.0        | stable   |        | PUBLISHED |              |
      | 34c126d5-1a1f-4571-acfb-77ca33e8ddd0 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | 9baf459d-1bfe-429e-884e-926597b1d32f | 1.0.0        | stable   |        | PUBLISHED |              |
      | d1bb5fca-0afc-4464-b321-4bd45cca8c7a | 6198261a-48b5-4445-a045-9fed4afc7735 | 5666d47e-936e-4d48-8dd7-382d32462b4e | 1.0.0        | stable   |        | PUBLISHED |              |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 5666d47e-936e-4d48-8dd7-382d32462b4e | 1.1.0        | stable   |        | PUBLISHED |              |
      | 04d3d9da-4e91-4634-9aa0-41e39a23658c | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | 0.0.1        | stable   |        | PUBLISHED |              |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename                  | filetype | checksum                                                                                 | status   | created_at               | updated_at               |
      | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0.tgz             | tgz      | ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d                                                 | UPLOADED | 2024-10-01T01:42:00.000Z | 2024-10-01T01:42:00.000Z |
      | ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0 | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1.tgz             | tgz      | d363c888471a1e0f6c7adadd1d27407bbecaae40f8fac3032fa6cb495ef5ee6b                         | UPLOADED | 2024-10-02T01:42:00.000Z | 2024-10-02T01:42:00.000Z |
      | 55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0.tgz             | tgz      | jpx0/ZlKmoe+IShOgMe8nQrlXtkTWdWmouBMIyKU/F1zH4b2Gr5myKMRBX6/d3vFoXbm9kAQigiTe+FP1OtmOw== | UPLOADED | 2024-10-03T01:42:00.000Z | 2024-10-03T01:42:00.000Z |
      | 346bd7fd-79fa-4ede-ac55-3ea07ed4cab2 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | test-bar-1.0.0-beta.1.tgz | tgz      |                                                                                          | UPLOADED | 2024-10-04T01:42:00.000Z | 2024-10-04T01:42:00.000Z |
      | c8aa34a7-3925-479b-9785-ada9a3736867 | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | test-bar-1.0.0-beta.2.tgz | tgz      | s9oHSNkgZBqfR5Rb7gTSQd3Q9eM=                                                             | UPLOADED | 2024-10-05T01:42:00.000Z | 2024-10-05T01:42:00.000Z |
      | b95ec07b-1210-4ddc-920e-6008a5c8ed3c | 56f66b77-f447-4300-828b-5cf92e457376 | test-bar-1.0.0-beta.3.tgz | tgz      | p1ax51VFmASfiviU4+gDrB68BGCTV0frC1fTZ67NJUirj96w5qrOmFWX7Jp0yb27                         | UPLOADED | 2024-10-06T01:42:00.000Z | 2024-10-06T01:42:00.000Z |
      | 9b0fa689-36c3-4b1f-be82-382238a2c5d0 | 0b5bb946-7346-448b-90a0-e8bbc02570e2 | baz-1.0.0.tgz             | tgz      | 8633b5884fb21b8e88cee36e37826c38f0a594bd                                                 | UPLOADED | 2024-10-07T01:42:00.000Z | 2024-10-07T01:42:00.000Z |
      | b6049631-dac8-49b6-a923-78f022cb1dbe | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0.tgz             | tgz      | 02PIiEcaHg9setrdHSdAe77KrkD4+sMDL6bLSV717ms=                                             | UPLOADED | 2024-10-08T01:42:00.000Z | 2024-10-08T01:42:00.000Z |
      | df4474cb-2a7b-4f75-8f27-2b99320e0164 | 00c9c981-8a75-494b-9207-71a829665729 | qux-1.0.0.tgz             | tgz      | 178b4b82a108a60c2b139987263be960f2dd35e1                                                 | UPLOADED | 2024-10-09T01:42:00.000Z | 2024-10-09T01:42:00.000Z |
      | f52378c0-1d1c-45f6-bff3-3231a99dfb27 | e00475de-edcc-4571-adec-5ef1b91ddb85 | qux-1.0.1.tgz             | tgz      |                                                                                          | WAITING  | 2024-10-10T01:42:00.000Z | 2024-10-10T01:42:00.000Z |
      | 200ef3e5-00f2-4eed-92fd-8f41cd19e8ed | 34c126d5-1a1f-4571-acfb-77ca33e8ddd0 | test-qux-1.0.0.tgz        | tgz      | 40937fdb052b47c1c79fd96c769b4b8fb37cffd3                                                 | UPLOADED | 2024-10-11T01:42:00.000Z | 2024-10-11T01:42:00.000Z |
      | e7c08c5d-0e1a-439f-8730-3cc5ed8399b9 | d1bb5fca-0afc-4464-b321-4bd45cca8c7a | quxx-1.0.0.tgz            | tgz      | 7f5fce1ecd30ec0b65dc5d9ee8768c0980421c3f                                                 | FAILED   | 2024-10-12T01:42:00.000Z | 2024-10-12T01:42:00.000Z |
      | 5acc0c22-0b7e-43f5-8168-8d341cccbaa6 | 70c40946-4b23-408c-aa1c-fa35421ff46a | quxx-1.1.0.tgz            | tgz      | b92b806b08a8dd817ae6205b52759fc57c4dff19                                                 | UPLOADED | 2024-10-13T01:42:00.000Z | 2024-10-13T01:42:00.000Z |
      | 22af171a-be06-47b1-bec3-3b2f8974990a | 04d3d9da-4e91-4634-9aa0-41e39a23658c | corge-1.1.0.tgz           | tgz      |                                                                                          | UPLOADED | 2024-10-14T01:42:00.000Z | 2024-10-14T01:42:00.000Z |
    And the current account has the following "manifest" rows:
      | release_artifact_id                  | release_id                           | content                                                                                                                                                                                                                                                               |
      | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | {"name":"foo","version":"1.0.0","description":"A basic mock package for testing","main":"index.js","author":"Test Author","license":"MIT","dependencies":{"lodash":"^4.17.21"},"scripts":{"start":"node index.js"}}                                                   |
      | ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0 | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | {"name":"foo","version":"1.0.1","description":"A basic mock package for testing","main":"index.js","author":"Test Author","license":"MIT","dependencies":{"lodash":"^4.17.21"},"scripts":{"start":"node index.js"}}                                                   |
      | 55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | {"name":"foo","version":"1.1.0","description":"A basic mock package for testing","main":"index.js","author":"Test Author","license":"MIT","dependencies":{"lodash":"^4.17.21"},"scripts":{"start":"node index.js"}}                                                   |
      | 346bd7fd-79fa-4ede-ac55-3ea07ed4cab2 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | {"name":"@test/bar","version":"1.0.0-beta.1","description":"A beta package with dev dependencies","main":"app.js","author":"Test Author","license":"Apache-2.0","devDependencies":{"jest":"^27.0.6","eslint":"^7.32.0"},"scripts":{"test":"jest","lint":"eslint ."}}  |
      | c8aa34a7-3925-479b-9785-ada9a3736867 | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | {"name":"@test/bar","version":"1.0.0-beta.2","description":"A beta package with dev dependencies","main":"app.js","author":"Test Author","license":"Apache-2.0","devDependencies":{"jest":"^27.0.6","eslint":"^7.32.0"},"scripts":{"test":"jest","lint":"eslint ."}}  |
      | b95ec07b-1210-4ddc-920e-6008a5c8ed3c | 56f66b77-f447-4300-828b-5cf92e457376 | {"name":"@test/bar","version":"1.0.0-beta.3","description":"A beta package with dev dependencies","main":"app.js","author":"Test Author","license":"Apache-2.0","devDependencies":{"jest":"^27.0.6","eslint":"^7.32.0"},"scripts":{"test":"jest","lint":"eslint ."}}  |
      | 9b0fa689-36c3-4b1f-be82-382238a2c5d0 | 0b5bb946-7346-448b-90a0-e8bbc02570e2 | {"name":"baz","version":"1.0.0","description":"A package with peer dependencies","main":"src/index.js","author":"Test Maintainer","license":"GPL-3.0","peerDependencies":{"react":"^17.0.2"}}                                                                         |
      | b6049631-dac8-49b6-a923-78f022cb1dbe | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | {"name":"baz","version":"2.0.0","description":"A package with peer dependencies","main":"src/index.js","author":"Test Maintainer","license":"GPL-3.0","peerDependencies":{"react":"^17.0.2"}}                                                                         |
      | df4474cb-2a7b-4f75-8f27-2b99320e0164 | 00c9c981-8a75-494b-9207-71a829665729 | {"name":"qux","version":"1.0.0","description":"A simple package with minimal setup","main":"main.js","author":"Jane Doe","license":"BSD-2-Clause"}                                                                                                                    |
      | 200ef3e5-00f2-4eed-92fd-8f41cd19e8ed | 34c126d5-1a1f-4571-acfb-77ca33e8ddd0 | {"name":"@test/qux","version":"1.0.0","description":"A scoped package with dependencies","main":"dist/index.js","author":"Beta Tester","license":"MIT","dependencies":{"axios":"^0.21.1"},"scripts":{"build":"webpack --config webpack.config.js"}}                   |
      | 22af171a-be06-47b1-bec3-3b2f8974990a | 04d3d9da-4e91-4634-9aa0-41e39a23658c | {"name":"corge","version":"1.0.0","description":"A package with both peer and dev dependencies","main":"src/app.js","author":"John Smith","license":"MIT","peerDependencies":{"vue":"^3.0.0"},"devDependencies":{"rollup":"^2.52.7"},"scripts":{"build":"rollup -c"}} |
    And I send the following raw headers:
      """
      User-Agent: npm/10.8.1 node/v22.3.0 linux x64 workspaces/false
      Accept: application/json
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//npm.pkg.keygen.sh/test1/foo"
    Then the response status should be "200"

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//npm.pkg.keygen.sh/foo"
    Then the response status should be "200"

  Scenario: Endpoint should only respond in JSON
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: text/html
      """
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "400"

  Scenario: Endpoint should return unscoped package metadata
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-03T01:42:00.000Z",
          "1.1.0": "2024-10-03T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.1.0": {
            "name": "foo",
            "version": "1.1.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8/foo-1.1.0.tgz",
              "integrity": "sha512-jpx0/ZlKmoe+IShOgMe8nQrlXtkTWdWmouBMIyKU/F1zH4b2Gr5myKMRBX6/d3vFoXbm9kAQigiTe+FP1OtmOw=="
            }
          },
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: Endpoint should return scoped package metadata
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/@test/bar"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "@test/bar",
        "time": {
          "created": "2024-10-02T01:23:45.000Z",
          "modified": "2024-10-06T01:42:00.000Z",
          "1.0.0-beta.3": "2024-10-06T01:42:00.000Z",
          "1.0.0-beta.2": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.1": "2024-10-04T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.0-beta.3",
          "beta": "1.0.0-beta.2"
        },
        "versions": {
          "1.0.0-beta.3": {
            "name": "@test/bar",
            "version": "1.0.0-beta.3",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/b95ec07b-1210-4ddc-920e-6008a5c8ed3c/test-bar-1.0.0-beta.3.tgz",
              "integrity": "sha384-p1ax51VFmASfiviU4+gDrB68BGCTV0frC1fTZ67NJUirj96w5qrOmFWX7Jp0yb27"
            }
          },
          "1.0.0-beta.2": {
            "name": "@test/bar",
            "version": "1.0.0-beta.2",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/c8aa34a7-3925-479b-9785-ada9a3736867/test-bar-1.0.0-beta.2.tgz"
            }
          },
          "1.0.0-beta.1": {
            "name": "@test/bar",
            "version": "1.0.0-beta.1",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/346bd7fd-79fa-4ede-ac55-3ea07ed4cab2/test-bar-1.0.0-beta.1.tgz"
            }
          }
        }
      }
      """

  Scenario: Endpoint should return scoped package metadata (encoded package)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/@test%2Fqux"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "@test/qux",
        "time": {
          "created": "2024-10-06T01:23:45.000Z",
          "modified": "2024-10-11T01:42:00.000Z",
          "1.0.0": "2024-10-11T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.0"
        },
        "versions": {
          "1.0.0": {
            "name": "@test/qux",
            "version": "1.0.0",
            "description": "A scoped package with dependencies",
            "main": "dist/index.js",
            "author": "Beta Tester",
            "license": "MIT",
            "dependencies": {
              "axios": "^0.21.1"
            },
            "scripts": {
              "build": "webpack --config webpack.config.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/200ef3e5-00f2-4eed-92fd-8f41cd19e8ed/test-qux-1.0.0.tgz",
              "shasum": "40937fdb052b47c1c79fd96c769b4b8fb37cffd3"
            }
          }
        }
      }
      """

  Scenario: Endpoint should support etags (match)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"68fca08fa381b6979de4b675868cf283"
      """
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "304"

  Scenario: Endpoint should support etags (mismatch)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"foo"
      """
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Etag: W/"68fca08fa381b6979de4b675868cf283"
      Cache-Control: max-age=86400, private
      """

  Scenario: Endpoint should return an error for a package without any versions
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/@test/baz"
    Then the response status should be "404"

  Scenario: Endpoint should return an error for a package that doesn't exist
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/invalid"
    Then the response status should be "404"

  Scenario: Product retrieves a unscoped package
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-03T01:42:00.000Z",
          "1.1.0": "2024-10-03T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.1.0": {
            "name": "foo",
            "version": "1.1.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8/foo-1.1.0.tgz",
              "integrity": "sha512-jpx0/ZlKmoe+IShOgMe8nQrlXtkTWdWmouBMIyKU/F1zH4b2Gr5myKMRBX6/d3vFoXbm9kAQigiTe+FP1OtmOw=="
            }
          },
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: Product retrieves a scoped package
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/@test/bar"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "@test/bar",
        "time": {
          "created": "2024-10-02T01:23:45.000Z",
          "modified": "2024-10-06T01:42:00.000Z",
          "1.0.0-beta.3": "2024-10-06T01:42:00.000Z",
          "1.0.0-beta.2": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.1": "2024-10-04T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.0-beta.3",
          "beta": "1.0.0-beta.2"
        },
        "versions": {
          "1.0.0-beta.3": {
            "name": "@test/bar",
            "version": "1.0.0-beta.3",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/b95ec07b-1210-4ddc-920e-6008a5c8ed3c/test-bar-1.0.0-beta.3.tgz",
              "integrity": "sha384-p1ax51VFmASfiviU4+gDrB68BGCTV0frC1fTZ67NJUirj96w5qrOmFWX7Jp0yb27"
            }
          },
          "1.0.0-beta.2": {
            "name": "@test/bar",
            "version": "1.0.0-beta.2",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/c8aa34a7-3925-479b-9785-ada9a3736867/test-bar-1.0.0-beta.2.tgz"
            }
          },
          "1.0.0-beta.1": {
            "name": "@test/bar",
            "version": "1.0.0-beta.1",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/346bd7fd-79fa-4ede-ac55-3ea07ed4cab2/test-bar-1.0.0-beta.1.tgz"
            }
          }
        }
      }
      """

  Scenario: Product retrieves their open package
    Given I am product "test2" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/baz"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "baz",
        "time": {
          "created": "2024-10-03T01:23:45.000Z",
          "modified": "2024-10-08T01:42:00.000Z",
          "2.0.0": "2024-10-08T01:42:00.000Z",
          "1.0.0": "2024-10-07T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "2.0.0"
        },
        "versions": {
          "2.0.0": {
            "name": "baz",
            "version": "2.0.0",
            "description": "A package with peer dependencies",
            "main": "src/index.js",
            "author": "Test Maintainer",
            "license": "GPL-3.0",
            "peerDependencies": {
              "react": "^17.0.2"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/b6049631-dac8-49b6-a923-78f022cb1dbe/baz-2.0.0.tgz",
              "integrity": "sha256-02PIiEcaHg9setrdHSdAe77KrkD4+sMDL6bLSV717ms="
            }
          },
          "1.0.0": {
            "name": "baz",
            "version": "1.0.0",
            "description": "A package with peer dependencies",
            "main": "src/index.js",
            "author": "Test Maintainer",
            "license": "GPL-3.0",
            "peerDependencies": {
              "react": "^17.0.2"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/9b0fa689-36c3-4b1f-be82-382238a2c5d0/baz-1.0.0.tgz",
              "shasum": "8633b5884fb21b8e88cee36e37826c38f0a594bd"
            }
          }
        }
      }
      """

  Scenario: Product retrieves an open package
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/baz"
    Then the response status should be "404"

  Scenario: Product retrieves a another product's package
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/baz"
    Then the response status should be "404"

  Scenario: License retrieves an unscoped package (entitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-03T01:42:00.000Z",
          "1.1.0": "2024-10-03T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.1.0": {
            "name": "foo",
            "version": "1.1.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8/foo-1.1.0.tgz",
              "integrity": "sha512-jpx0/ZlKmoe+IShOgMe8nQrlXtkTWdWmouBMIyKU/F1zH4b2Gr5myKMRBX6/d3vFoXbm9kAQigiTe+FP1OtmOw=="
            }
          },
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: License retrieves an unscoped package (unentitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-02T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: License retrieves a scoped package
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/npm/@test/bar"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "@test/bar",
        "time": {
          "created": "2024-10-02T01:23:45.000Z",
          "modified": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.2": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.1": "2024-10-04T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.0-beta.2",
          "beta": "1.0.0-beta.2"
        },
        "versions": {
          "1.0.0-beta.2": {
            "name": "@test/bar",
            "version": "1.0.0-beta.2",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/c8aa34a7-3925-479b-9785-ada9a3736867/test-bar-1.0.0-beta.2.tgz"
            }
          },
          "1.0.0-beta.1": {
            "name": "@test/bar",
            "version": "1.0.0-beta.1",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/346bd7fd-79fa-4ede-ac55-3ea07ed4cab2/test-bar-1.0.0-beta.1.tgz"
            }
          }
        }
      }
      """

  Scenario: License retrieves a package for a different product
    Given the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "404"

  Scenario: License retrieves an open package
    Given the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/npm/baz"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "baz",
        "time": {
          "created": "2024-10-03T01:23:45.000Z",
          "modified": "2024-10-08T01:42:00.000Z",
          "2.0.0": "2024-10-08T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "2.0.0"
        },
        "versions": {
          "2.0.0": {
            "name": "baz",
            "version": "2.0.0",
            "description": "A package with peer dependencies",
            "main": "src/index.js",
            "author": "Test Maintainer",
            "license": "GPL-3.0",
            "peerDependencies": {
              "react": "^17.0.2"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/b6049631-dac8-49b6-a923-78f022cb1dbe/baz-2.0.0.tgz",
              "integrity": "sha256-02PIiEcaHg9setrdHSdAe77KrkD4+sMDL6bLSV717ms="
            }
          }
        }
      }
      """

  Scenario: User retrieves an unscoped package (with entitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-03T01:42:00.000Z",
          "1.1.0": "2024-10-03T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.1.0": {
            "name": "foo",
            "version": "1.1.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8/foo-1.1.0.tgz",
              "integrity": "sha512-jpx0/ZlKmoe+IShOgMe8nQrlXtkTWdWmouBMIyKU/F1zH4b2Gr5myKMRBX6/d3vFoXbm9kAQigiTe+FP1OtmOw=="
            }
          },
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: User retrieves an unscoped package (with unentitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-02T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: User retrieves a scoped package
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/@test/bar"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "@test/bar",
        "time": {
          "created": "2024-10-02T01:23:45.000Z",
          "modified": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.2": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.1": "2024-10-04T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.0-beta.2",
          "beta": "1.0.0-beta.2"
        },
        "versions": {
          "1.0.0-beta.2": {
            "name": "@test/bar",
            "version": "1.0.0-beta.2",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/c8aa34a7-3925-479b-9785-ada9a3736867/test-bar-1.0.0-beta.2.tgz"
            }
          },
          "1.0.0-beta.1": {
            "name": "@test/bar",
            "version": "1.0.0-beta.1",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/346bd7fd-79fa-4ede-ac55-3ea07ed4cab2/test-bar-1.0.0-beta.1.tgz"
            }
          }
        }
      }
      """

  Scenario: User retrieves an unscoped package (with entitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-03T01:42:00.000Z",
          "1.1.0": "2024-10-03T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.1.0": {
            "name": "foo",
            "version": "1.1.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8/foo-1.1.0.tgz",
              "integrity": "sha512-jpx0/ZlKmoe+IShOgMe8nQrlXtkTWdWmouBMIyKU/F1zH4b2Gr5myKMRBX6/d3vFoXbm9kAQigiTe+FP1OtmOw=="
            }
          },
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: User retrieves an unscoped package (with unentitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "foo",
        "time": {
          "created": "2024-10-01T01:23:45.000Z",
          "modified": "2024-10-02T01:42:00.000Z",
          "1.0.1": "2024-10-02T01:42:00.000Z",
          "1.0.0": "2024-10-01T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.1"
        },
        "versions": {
          "1.0.1": {
            "name": "foo",
            "version": "1.0.1",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0/foo-1.0.1.tgz"
            }
          },
          "1.0.0": {
            "name": "foo",
            "version": "1.0.0",
            "description": "A basic mock package for testing",
            "main": "index.js",
            "author": "Test Author",
            "license": "MIT",
            "dependencies": {
              "lodash": "^4.17.21"
            },
            "scripts": {
              "start": "node index.js"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/5762c549-7f5b-4a73-9873-3acdb1213fe8/foo-1.0.0.tgz",
              "shasum": "ad4d7c2a5b16c146ff6514327e43958aa9b8cc8d"
            }
          }
        }
      }
      """

  Scenario: User retrieves a scoped package
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/@test/bar"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "@test/bar",
        "time": {
          "created": "2024-10-02T01:23:45.000Z",
          "modified": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.2": "2024-10-05T01:42:00.000Z",
          "1.0.0-beta.1": "2024-10-04T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "1.0.0-beta.2",
          "beta": "1.0.0-beta.2"
        },
        "versions": {
          "1.0.0-beta.2": {
            "name": "@test/bar",
            "version": "1.0.0-beta.2",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/c8aa34a7-3925-479b-9785-ada9a3736867/test-bar-1.0.0-beta.2.tgz"
            }
          },
          "1.0.0-beta.1": {
            "name": "@test/bar",
            "version": "1.0.0-beta.1",
            "description": "A beta package with dev dependencies",
            "main": "app.js",
            "author": "Test Author",
            "license": "Apache-2.0",
            "devDependencies": {
              "jest": "^27.0.6",
              "eslint": "^7.32.0"
            },
            "scripts": {
              "test": "jest",
              "lint": "eslint ."
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/346bd7fd-79fa-4ede-ac55-3ea07ed4cab2/test-bar-1.0.0-beta.1.tgz"
            }
          }
        }
      }
      """

  Scenario: User retrieves a licensed package (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "404"

  Scenario: User retrieves an open package (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/npm/baz"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "baz",
        "time": {
          "created": "2024-10-03T01:23:45.000Z",
          "modified": "2024-10-08T01:42:00.000Z",
          "2.0.0": "2024-10-08T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "2.0.0"
        },
        "versions": {
          "2.0.0": {
            "name": "baz",
            "version": "2.0.0",
            "description": "A package with peer dependencies",
            "main": "src/index.js",
            "author": "Test Maintainer",
            "license": "GPL-3.0",
            "peerDependencies": {
              "react": "^17.0.2"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/b6049631-dac8-49b6-a923-78f022cb1dbe/baz-2.0.0.tgz",
              "integrity": "sha256-02PIiEcaHg9setrdHSdAe77KrkD4+sMDL6bLSV717ms="
            }
          }
        }
      }
      """

  Scenario: Anon retrieves a closed package
    When I send a GET request to "/accounts/test1/engines/npm/corge"
    Then the response status should be "404"

  Scenario: Anon retrieves a licensed package
    When I send a GET request to "/accounts/test1/engines/npm/foo"
    Then the response status should be "404"

  Scenario: Anon retrieves an open package
    When I send a GET request to "/accounts/test1/engines/npm/baz"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "name": "baz",
        "time": {
          "created": "2024-10-03T01:23:45.000Z",
          "modified": "2024-10-08T01:42:00.000Z",
          "2.0.0": "2024-10-08T01:42:00.000Z"
        },
        "dist-tags": {
          "latest": "2.0.0"
        },
        "versions": {
          "2.0.0": {
            "name": "baz",
            "version": "2.0.0",
            "description": "A package with peer dependencies",
            "main": "src/index.js",
            "author": "Test Maintainer",
            "license": "GPL-3.0",
            "peerDependencies": {
              "react": "^17.0.2"
            },
            "dist": {
              "tarball": "https://api.keygen.sh/v1/accounts/14c038fd-b57e-432d-8c09-f50ebcd6a7bc/artifacts/b6049631-dac8-49b6-a923-78f022cb1dbe/baz-2.0.0.tgz",
              "integrity": "sha256-02PIiEcaHg9setrdHSdAe77KrkD4+sMDL6bLSV717ms="
            }
          }
        }
      }
      """
