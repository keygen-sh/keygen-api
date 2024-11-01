@api/v1
Feature: Raw artifact download
  Background:
    Given the following "accounts" exist:
      | id                                   | name   | slug   |
      | 29b60e24-f18a-4c6a-9e86-da3116c52f30 | Keygen | keygen |
    And the current account is "keygen"
    And the current account has the following "product" rows:
      | id                                   | name  | code  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | CLI   | cli   |
      | a8fd2a04-73ce-4647-bccb-29c53773096e | Dup   | dup   |
      | fbfc7c51-56a5-4523-81ec-f13c5c616d2e | Relay | relay |
      | 9a1f5382-6abc-477c-bf22-a5a2376a9aa7 | Test  | test  |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | engine | key   |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | fbfc7c51-56a5-4523-81ec-f13c5c616d2e | raw    | relay |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | 9a1f5382-6abc-477c-bf22-a5a2376a9aa7 | tauri  | test  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | tag    | version      | channel  | status    |
      # cli
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      |        | 1.0.0-beta.1 | beta     | PUBLISHED |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      |        | 1.0.0        | stable   | PUBLISHED |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | latest | 1.1.0        | stable   | PUBLISHED |
      | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      |        | 1.2.0-beta.1 | beta     | PUBLISHED |
      # dup
      | 2ed811e3-616d-4af9-a0c4-e9da0cd46e0e | a8fd2a04-73ce-4647-bccb-29c53773096e |                                      |        | 1.0.0-beta.1 | beta     | PUBLISHED |
      # relay
      | c77ba874-de62-4a17-8368-fc10db1e1c80 | fbfc7c51-56a5-4523-81ec-f13c5c616d2e | 2f8af04a-2424-4ca2-8480-6efe24318d1a |        | 1.0.0-beta.1 | beta     | PUBLISHED |
      | 29f74047-265f-452c-9d64-779621682857 | fbfc7c51-56a5-4523-81ec-f13c5c616d2e | 2f8af04a-2424-4ca2-8480-6efe24318d1a |        | 1.0.0-beta.2 | beta     | DRAFT     |
      | 791b6131-7ff2-4f29-84b5-70aae22788e1 | fbfc7c51-56a5-4523-81ec-f13c5c616d2e | 2f8af04a-2424-4ca2-8480-6efe24318d1a | latest | 1.0.0        | stable   | PUBLISHED |
      # test
      | cc73640c-074c-497d-a516-1e312b314082 | 9a1f5382-6abc-477c-bf22-a5a2376a9aa7 | 7b113ac2-ae81-406a-b44e-f356126e2faa | latest | 1.2.3        | stable   | PUBLISHED |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename                 | filetype | platform | arch   | status   |
      # cli/1.0.0-beta.1
      | e1a9d063-cd8d-4655-95e5-647c961852eb | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | keygen_linux_amd64       |          | linux    | amd64  | UPLOADED |
      | 16b9a3fa-6b12-4d86-b81e-be2757392bae | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | keygen_linux_arm64       |          | linux    | arm64  | UPLOADED |
      | 61987e0a-1848-4a04-9b2a-86ff6a7f464b | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | keygen_linux_386         |          | linux    | 386    | UPLOADED |
      | dd61752e-187e-4346-a7df-fda80adb7131 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | keygen_linux_arm         |          | linux    | arm    | UPLOADED |
      # dup/1.0.0-beta.1
      | dda288c7-cb7d-4c1e-b9fc-6b9a5a3a7fab | 2ed811e3-616d-4af9-a0c4-e9da0cd46e0e | keygen_linux_amd64       |          | linux    | amd64  | UPLOADED |
      # cli/1.0.0
      | 1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_linux_amd64       |          | linux    | amd64  | UPLOADED |
      | c1f8705e-68cd-4312-b2b1-72e19df47bd1 | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_linux_arm64       |          | linux    | arm64  | UPLOADED |
      | adce1d8b-7120-43b6-a42a-a64c24ed2a25 | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_linux_386         |          | linux    | 386    | UPLOADED |
      | 2e520ddb-d3a3-4be6-a8bf-978351ee6f58 | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_linux_arm         |          | linux    | arm    | UPLOADED |
      | 2fd19ae7-e0cf-4de0-ad4a-1ca65db75c87 | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_darwin_amd64      |          | darwin   | amd64  | UPLOADED |
      | a8e49ea6-17df-4798-937f-e4756e331db5 | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_darwin_arm64      |          | darwin   | arm64  | UPLOADED |
      | fa773c2b-1c3a-4bd8-83fe-546480e92098 | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_windows_amd64.exe | exe      | windows  | amd64  | UPLOADED |
      | 1cccff81-8b49-40b2-9453-3456f2ca04ac | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_windows_arm64.exe | exe      | windows  | arm64  | UPLOADED |
      | ab3f9749-3ea7-4057-92ec-d647784ff097 | 757e0a41-835e-42ad-bad8-84cabd29c72a | keygen_windows_386.exe   | exe      | windows  | 386    | UPLOADED |
      | a2fd1960-54c6-4624-83d1-84f0c8dd1f1a | 757e0a41-835e-42ad-bad8-84cabd29c72a | install.sh               | sh       |          |        | UPLOADED |
      | c1eede5b-1189-4797-8744-4b6e109dccda | 757e0a41-835e-42ad-bad8-84cabd29c72a | version                  | txt      |          |        | UPLOADED |
      # cli/1.1.0
      | 00aeec65-165c-487c-8e22-7ab454319b0f | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_linux_amd64       |          | linux    | amd64  | UPLOADED |
      | 65132a0a-4ca9-4422-b836-0cd39b0a94f7 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_linux_arm64       |          | linux    | arm64  | UPLOADED |
      | 77aaaf13-cfc3-4339-8350-163efcaf8814 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_linux_386         |          | linux    | 386    | UPLOADED |
      | 8bdc0604-6948-4ab7-82bc-2b9a19153367 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_linux_arm         |          | linux    | arm    | UPLOADED |
      | 2133955c-137f-4422-9290-9a364b1a40a0 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_darwin_amd64      |          | darwin   | amd64  | UPLOADED |
      | ba8dd592-2c3e-46bf-afdc-dabc2fed9d8e | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_darwin_arm64      |          | darwin   | arm64  | UPLOADED |
      | eaa67d65-f596-427a-8f64-80a7125ae299 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_windows_amd64.exe | exe      | windows  | amd64  | UPLOADED |
      | c185d92b-1232-4bdd-9906-fa4d99e259c7 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_windows_arm64.exe | exe      | windows  | arm64  | UPLOADED |
      | adc403d1-1e2e-4ffe-a6d2-d9c81d9815e0 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | keygen_windows_386.exe   | exe      | windows  | 386    | UPLOADED |
      | ac537875-99a0-4b54-b4f6-4423d7547401 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | install.sh               | sh       |          |        | UPLOADED |
      | 0f60b059-210d-4bf5-8b1a-9195ad6f4501 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | version                  | txt      |          |        | UPLOADED |
      # cli/1.2.0-beta.1
      | 05f8a823-b80b-4453-a524-82332fc50792 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_linux_amd64       |          | linux    | amd64  | UPLOADED |
      | 1eff1d91-02ff-44ec-8b44-1a11c10461ab | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_linux_arm64       |          | linux    | arm64  | UPLOADED |
      | 4502501f-8371-4aa8-acac-fff32c204a41 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_linux_386         |          | linux    | 386    | UPLOADED |
      | 260b1b8d-bf7e-4738-bad0-5316373da8f5 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_linux_arm         |          | linux    | arm    | UPLOADED |
      | d5405732-577f-42eb-bd53-3bbc524072f0 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_darwin_amd64      |          | darwin   | amd64  | UPLOADED |
      | 419ba987-9184-4baf-82bf-8ca9baa4e267 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_darwin_arm64      |          | darwin   | arm64  | UPLOADED |
      | becabe1f-4b3f-4a83-9ab4-27fdb1ba07fe | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_windows_amd64.exe | exe      | windows  | amd64  | UPLOADED |
      | d2801d8a-5ce8-4c48-89ee-7177d7dcc84c | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_windows_arm64.exe | exe      | windows  | arm64  | UPLOADED |
      | b7f57cf1-15ce-46bd-9120-c1a9b189c06d | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | keygen_windows_386.exe   | exe      | windows  | 386    | UPLOADED |
      | 60cf1b85-cbfd-4a6b-89cf-bb7ad3a8d027 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | install.sh               | sh       |          |        | UPLOADED |
      | 0d0ca391-e8e6-43e6-9113-ea13c1e3cbed | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | version                  | txt      |          |        | UPLOADED |
      # relay/1.0.0-beta.1
      | 55ffcc9b-325e-4dfd-9976-9ff106441e7f | c77ba874-de62-4a17-8368-fc10db1e1c80 | relay_linux_amd64        |          | linux    | amd64  | UPLOADED |
      | 99fb62e8-a72e-4e05-8464-1a7beef423a2 | c77ba874-de62-4a17-8368-fc10db1e1c80 | relay_linux_arm64        |          | linux    | arm64  | UPLOADED |
      | 2532cb63-3040-4d57-9b79-814035b19498 | c77ba874-de62-4a17-8368-fc10db1e1c80 | relay_linux_386          |          | linux    | 386    | UPLOADED |
      | 93787e60-731d-45f5-a467-bcac51a80f17 | c77ba874-de62-4a17-8368-fc10db1e1c80 | relay_linux_arm          |          | linux    | arm    | UPLOADED |
      | 7acbd5a5-a7ee-429b-8029-d95d6181bece | c77ba874-de62-4a17-8368-fc10db1e1c80 | relay_windows_amd64.exe  | exe      | windows  | amd64  | UPLOADED |
      | 86e5bb99-c77c-4988-b426-a0740ba68bb9 | c77ba874-de62-4a17-8368-fc10db1e1c80 | relay_windows_arm64.exe  | exe      | windows  | arm64  | UPLOADED |
      | 8a132eee-6ea8-4d3c-a029-67be30a0c274 | c77ba874-de62-4a17-8368-fc10db1e1c80 | relay_windows_386.exe    | exe      | windows  | 386    | UPLOADED |
      | c811f16c-18e5-40d6-9130-ba9ce2df0df9 | c77ba874-de62-4a17-8368-fc10db1e1c80 | install.sh               | sh       |          |        | UPLOADED |
      | c6e5b4b6-1e36-43e2-85f6-a3cf99686da6 | c77ba874-de62-4a17-8368-fc10db1e1c80 | version                  | txt      |          |        | UPLOADED |
      # relay/1.0.0-beta.2
      | 73bf0858-d72f-48d8-84a7-3495efc79bc0 | 29f74047-265f-452c-9d64-779621682857 | relay_linux_amd64        |          | linux    | amd64  | UPLOADED |
      | 38129484-4ed7-45b1-bc51-31821b37a896 | 29f74047-265f-452c-9d64-779621682857 | relay_linux_arm64        |          | linux    | arm64  | UPLOADED |
      | 527625d2-8e99-492a-921d-9aa98e83349a | 29f74047-265f-452c-9d64-779621682857 | relay_linux_386          |          | linux    | 386    | UPLOADED |
      | 9474bae4-2a68-4c65-8662-7e7a4cb8e021 | 29f74047-265f-452c-9d64-779621682857 | relay_linux_arm          |          | linux    | arm    | UPLOADED |
      | 5f1dd84f-9a25-4db2-b93f-d53a40514fcd | 29f74047-265f-452c-9d64-779621682857 | relay_windows_amd64.exe  | exe      | windows  | amd64  | UPLOADED |
      | 17dd49ca-1289-414a-870b-c3a084a5ddeb | 29f74047-265f-452c-9d64-779621682857 | relay_windows_arm64.exe  | exe      | windows  | arm64  | UPLOADED |
      | cd3e3d36-3411-4d49-8f95-9710f6ed2ff9 | 29f74047-265f-452c-9d64-779621682857 | relay_windows_386.exe    | exe      | windows  | 386    | UPLOADED |
      | 46810ac2-ce40-49ed-ab80-e1da4de2dcba | 29f74047-265f-452c-9d64-779621682857 | install.sh               | sh       |          |        | UPLOADED |
      | e84f5076-54fb-4cf5-95e2-a94685fc3e3c | 29f74047-265f-452c-9d64-779621682857 | version                  | txt      |          |        | UPLOADED |
      # relay/1.0.0
      | fd581495-4763-40f1-9b2b-9832e84c1c96 | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_linux_amd64        |          | linux    | amd64  | UPLOADED |
      | 2b5417c3-9200-424f-aa38-21aa44f90c3a | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_linux_arm64        |          | linux    | arm64  | UPLOADED |
      | 60294fa3-1f41-4f21-8323-6adb5f019279 | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_linux_386          |          | linux    | 386    | UPLOADED |
      | 021259e0-a933-440c-b327-2a46c8665f8c | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_linux_arm          |          | linux    | arm    | UPLOADED |
      | f210bd01-ccdd-4585-8b36-f881f67a14ca | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_darwin_amd64       |          | darwin   | amd64  | UPLOADED |
      | 7ece0078-f17f-4113-82a2-58c4a03ba272 | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_darwin_arm64       |          | darwin   | arm64  | UPLOADED |
      | adae18c0-51ba-4e5e-ad41-d64e250e503d | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_windows_amd64.exe  | exe      | windows  | amd64  | UPLOADED |
      | 09086316-2a7b-4418-879a-848075f15b4b | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_windows_arm64.exe  | exe      | windows  | arm64  | UPLOADED |
      | b49e82e3-911d-49b0-8548-15fbf1ffbdd6 | 791b6131-7ff2-4f29-84b5-70aae22788e1 | relay_windows_386.exe    | exe      | windows  | 386    | WAITING  |
      | cb89ca77-c879-45c7-8113-1a3a5e9b1b16 | 791b6131-7ff2-4f29-84b5-70aae22788e1 | install.sh               | sh       |          |        | UPLOADED |
      | daa7674d-5072-4290-af3d-387d798abb28 | 791b6131-7ff2-4f29-84b5-70aae22788e1 | version                  | txt      |          |        | UPLOADED |
      # test/1.2.3
      | ec313439-af2a-425d-8c4f-be1eef77126a | cc73640c-074c-497d-a516-1e312b314082 | myapp.AppImage           | appimage | linux    | x86_64 | UPLOADED |
      | c986d05e-0f14-486b-acee-fc41acad8a25 | cc73640c-074c-497d-a516-1e312b314082 | myapp.AppImage.sig       | sig      | linux    | x86_64 | UPLOADED |
      | 5a56ad95-031f-4b01-be2f-ecefe4902253 | cc73640c-074c-497d-a516-1e312b314082 | myapp.app                | app      | darwin   | x86_64 | UPLOADED |
      | a8b3b63c-6a03-4b55-8b97-18220140316c | cc73640c-074c-497d-a516-1e312b314082 | myapp.app.tar.gz         | gz       | darwin   | x86_64 | UPLOADED |
      | eebc7045-6fe0-41c0-a1a9-ba931feff294 | cc73640c-074c-497d-a516-1e312b314082 | myapp.app.tar.gz.sig     | sig      | darwin   | x86_64 | UPLOADED |
      | e3890cba-b190-437b-9a9b-e81de7f60fb2 | cc73640c-074c-497d-a516-1e312b314082 | myapp-setup.exe          | exe      | windows  | x86_64 | UPLOADED |
      | 3076e952-96b8-4f77-9048-ddc11172cd8c | cc73640c-074c-497d-a516-1e312b314082 | myapp-setup.exe.sig      | sig      | windows  | x86_64 | UPLOADED |
      | 99624561-dbe2-4b74-991c-66977197bd66 | cc73640c-074c-497d-a516-1e312b314082 | myapp.msi                | msi      | windows  | x86_64 | UPLOADED |
      | 8ebb2e21-84a7-4815-bcd6-f497a74f7dd9 | cc73640c-074c-497d-a516-1e312b314082 | myapp.msi.sig            | sig      | windows  | x86_64 | UPLOADED |
    And I send the following raw headers:
      """
      Accept: application/octet-stream
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "keygen" is canceled
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/cli/1.0.0/install.sh"
    Then the response status should be "403"

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "//raw.pkg.keygen.sh/keygen/relay/@relay/1.0.0-beta.1/install.sh"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://raw.pkg.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/c811f16c-18e5-40d6-9130-ba9ce2df0df9/install.sh" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "//raw.pkg.keygen.sh/relay/@relay/1.0.0-beta.1/install.sh"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://raw.pkg.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/c811f16c-18e5-40d6-9130-ba9ce2df0df9/install.sh" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should redirect when an artifact exists
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0-beta.1/install.sh"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/c811f16c-18e5-40d6-9130-ba9ce2df0df9/install.sh" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return error when an artifact does not exist (no artifact)
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/foobar.txt"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return error when an artifact does not exist (no release)
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/3.0.0/install.sh"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return error when an artifact does not exist (no package)
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/1.0.0-beta.1/install.sh"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return error when an artifact does not exist (no product)
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/rleay/@relay/1.0.0/install.sh"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should redirect for an artifact that is a duplicate of another
    Given I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/dup/1.0.0-beta.1/keygen_linux_amd64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/dda288c7-cb7d-4c1e-b9fc-6b9a5a3a7fab/keygen_linux_amd64" }
      """

  Scenario: Endpoint should redirect for an artifact for a Tauri package
    Given I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/test/@test/1.2.3/myapp.app"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/5a56ad95-031f-4b01-be2f-ecefe4902253/myapp.app" }
      """

  Scenario: Endpoint should redirect for an artfict without a package
    Given I am an admin of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/cli/1.0.0/keygen_linux_amd64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/keygen_linux_amd64" }
      """

  Scenario: Product downloads an artifact with a package scope
    Given the current account has 1 "webhook-endpoint"
    And I am product "relay" of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/latest/relay_linux_amd64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/fd581495-4763-40f1-9b2b-9832e84c1c96/relay_linux_amd64" }
      """

  Scenario: Product downloads an artifact without a package scope
    Given I am product "cli" of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/cli/latest/keygen_linux_amd64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/keygen_linux_amd64" }
      """

  Scenario: Product downloads an artifact for a different product
    Given I am product "relay" of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/cli/latest/keygen_linux_amd64"
    Then the response status should be "404"

  Scenario: Product downloads a draft artifact
    Given I am product "relay" of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0-beta.2/relay_linux_arm"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/9474bae4-2a68-4c65-8662-7e7a4cb8e021/relay_linux_arm" }
      """

  Scenario: Product downloads a waiting artifact
    Given I am product "relay" of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/relay_windows_386.exe"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/b49e82e3-911d-49b0-8548-15fbf1ffbdd6/relay_windows_386.exe" }
      """

  Scenario: License downloads an artifact they have access to
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/keygen/engines/raw/cli/1.0.0/keygen_darwin_arm64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/a8e49ea6-17df-4798-937f-e4756e331db5/keygen_darwin_arm64" }
      """

  Scenario: License downloads an artifact they don't have access to
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/relay_darwin_arm64"
    Then the response status should be "404"

  Scenario: License downloads a draft artifact
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0-beta.2/relay_linux_arm"
    Then the response status should be "404"

  Scenario: License downloads a waiting artifact
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/relay_windows_386.exe"
    Then the response status should be "404"

  Scenario: License retrieves an artifact that has constraints (missing entitlements)
    Given the current account has 2 "entitlements"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "releaseId": "$releases[791b6131-7ff2-4f29-84b5-70aae22788e1]",
        "entitlementId": "$entitlements[0]"
      }
      """
    And the current account has 1 "policy" with the following:
      """
      {
        "productId": "fbfc7c51-56a5-4523-81ec-f13c5c616d2e",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/relay_darwin_arm64"
    Then the response status should be "404"

  Scenario: License retrieves an artifact that has constraints (has entitlements)
    Given the current account has 2 "entitlements"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "releaseId": "$releases[791b6131-7ff2-4f29-84b5-70aae22788e1]",
        "entitlementId": "$entitlements[0]"
      }
      """
    And the current account has 1 "policy" with the following:
      """
      {
        "productId": "fbfc7c51-56a5-4523-81ec-f13c5c616d2e",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/relay_darwin_arm64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/7ece0078-f17f-4113-82a2-58c4a03ba272/relay_darwin_arm64" }
      """

  Scenario: Owner downloads an artifact they have access to
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/cli/1.0.0/keygen_darwin_arm64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/a8e49ea6-17df-4798-937f-e4756e331db5/keygen_darwin_arm64" }
      """

  Scenario: Owner downloads an artifact they don't have access to
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/relay_darwin_arm64"
    Then the response status should be "404"

  Scenario: User downloads an artifact they have access to
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/cli/1.0.0/keygen_darwin_arm64"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/a8e49ea6-17df-4798-937f-e4756e331db5/keygen_darwin_arm64" }
      """

  Scenario: User downloads an artifact they don't have access to
    Given the current account has 1 "policy" with the following:
      """
      {
        "productId": "6198261a-48b5-4445-a045-9fed4afc7735",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/raw/relay/@relay/1.0.0/relay_darwin_arm64"
    Then the response status should be "404"

  Scenario: Anonymous retrieves a licensed artifact
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    When I send a GET request to "/accounts/keygen/engines/raw/cli/latest/keygen_windows_arm64.exe"
    Then the response status should be "404"

  Scenario: Anonymous retrieves a closed artifact
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    When I send a GET request to "/accounts/keygen/engines/raw/cli/latest/keygen_windows_arm64.exe"
    Then the response status should be "404"

  Scenario: Anonymous retrieves an open artifact
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    When I send a GET request to "/accounts/keygen/engines/raw/cli/latest/keygen_windows_arm64.exe"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      { "Location": "https://api.keygen.sh/v1/accounts/29b60e24-f18a-4c6a-9e86-da3116c52f30/artifacts/c185d92b-1232-4bdd-9906-fa4d99e259c7/keygen_windows_arm64.exe" }
      """
