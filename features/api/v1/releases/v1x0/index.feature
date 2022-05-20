@api/v1.0 @deprecated
Feature: Create release

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases"
    Then the response status should be "403"

  Scenario: Admin retrieves all v1.0.0 releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?version=1.0.0"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "release"

  Scenario: Anonymous retrieves all v1.0.1 releases for their account (duplicates)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel  | api_version |
      | 936dbd12-fe27-4ee6-8c83-c3693b52f5b4 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 412b633e-c687-4c90-a4e0-6c388822980d | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | c3c79178-d9b5-4ec2-a901-779bc4524b93 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 1667547c-c604-4b7a-9272-f25f2ac7f62e | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 807eed2c-ffa6-41f3-bdf6-ad3d3ddead86 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 4aae91f5-b357-45f9-a691-d415d98a9807 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | e96a1898-af51-43a8-8b48-71448c419558 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | a45c089b-1ade-4dc5-95c3-0d58fe592e05 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | d25b4f7e-0e3f-45fd-9cd8-08a6151ce255 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | a40edf5c-8381-44bd-85be-43d0004a3c01 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 3173f542-309f-4055-8faa-61bd26ef81a3 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 472f06c7-a7f8-4807-978c-caaf017030ef | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 18a54a9b-732a-4589-8d75-fada7216659a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | fe9b3eaa-e6a0-4491-96a9-09de21213b91 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | c1483ef7-24da-4b30-bcbc-c24b0c46d98c | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | fe23cb05-cbef-4a28-8f48-31dfcad28f65 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | aebfbb06-bd9f-4cd8-b963-cf5ddb614cf7 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 60beb8bd-193e-48e7-8475-bb3bd2f52cc3 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | de8ef48c-1e28-442a-a8ab-39c0b45affc5 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 0ad0c51e-0f88-47a9-9b62-ce40872a5f49 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 346525f7-86b8-428f-91bf-ab361799cb11 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | f0b5d54b-27e0-4962-8051-19cea48a3c16 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | af061772-c2e3-43a2-a6e8-f9ed15af1e2e | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 19712632-4490-499e-8f3b-6f222306aaed | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 38e1621f-e4ef-4c08-8724-8cb2d909c2ae | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 6d47d326-b13e-4825-973b-22c1ac11dfca | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | a1ba77c9-0a29-4466-b0bd-6c16a77ccd77 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 4eeb44be-be26-411c-8376-51b9e74e152a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 78b4101a-b255-4edd-be7a-796330a6ebab | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 295cee65-a2a2-4a24-a315-2e9624e064ed | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 151eff1b-24ab-4b10-848f-662be052ed37 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | d59c45bc-bab1-4dda-9e08-25a2246c4d71 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 92bdc5de-4a4f-493a-9fad-18e14c29a2ad | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 67be74d9-99ff-4279-b150-14323d2b9a85 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 98d6681d-34c6-4aae-b4bd-3e239868c746 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 95dba803-3f63-459b-a0e5-0b973fa86bed | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 72974253-337b-4f1c-9614-04fda53819ef | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 258a923d-9c62-46c8-afa6-27c57794cdc1 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | db234a05-bbf8-40bf-b7fb-c1e909042f95 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | a75a1a64-268a-48d8-bdd4-7bfa7e4022d6 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 9bad932d-760b-4876-8b33-0e80ff8e017c | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 45657f1a-b376-4478-b42a-a9d538645b4c | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | a39a060c-47a0-4fcf-a043-568e0a871cf1 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 2c1d5af7-a522-43e2-b334-9fada4f80e7e | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | dfb38a19-14ac-48a0-8509-b5ca4af94ce6 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | d005cc2c-d30d-4720-b7e5-5af9ea3f4bdc | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 7e90e520-0438-46c4-80ca-0ac10c4573ba | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 6bd8b3e9-e6d2-4ab1-98a6-882602222802 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 9510866e-e548-4f4e-b833-371d64f663cf | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 287579a0-ed77-40c7-b3a1-6bc138ee12ab | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | d4c5596f-94eb-4a8c-a302-5d58753ae3c8 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | f417d870-4260-4562-bfc1-81feef49b191 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | e87e4109-34b4-483b-9704-7bae3c867b72 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 05235b88-960d-481a-83f8-cb2887c035ce | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 2e110690-ec48-48b9-8f06-71875ec23f5a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 41de93b6-5829-4299-a49c-f8d2ffd6d7eb | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | c6fc1988-9584-41fd-9681-414f87532386 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 5467af91-d88e-4b43-923c-a959a2b40be4 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | ad5d7877-ce82-486f-8029-b67a4e053bb2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 22065903-85a3-4760-b3ea-1f162e08956d | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | a3789fc0-c9d5-472b-8900-47f2639f4aa0 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 29e77342-233a-4cf6-abc6-e6d9d9b357e1 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | b17b67f8-6d50-46cd-b845-99219d0fa4af | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 4d5e23f8-bb32-4518-8dc2-7b2f8154d2ca | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 13d349ff-1cc9-42e5-8e5c-72b9b9e6b4a7 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
      | 840a0bf2-6bf5-4c1a-917f-26b289266202 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.1   | stable   | 1.0         |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                           | filetype | platform        |
      | 936dbd12-fe27-4ee6-8c83-c3693b52f5b4 | cli/version                        | txt      |                 |
      | 412b633e-c687-4c90-a4e0-6c388822980d | cli/install.sh                     | sh       |                 |
      | c3c79178-d9b5-4ec2-a901-779bc4524b93 | cli/keygen_windows_arm64_1_0_1.exe | exe      | windows/arm64   |
      | 1667547c-c604-4b7a-9272-f25f2ac7f62e | cli/keygen_windows_arm_1_0_1.exe   | exe      | windows/arm     |
      | 807eed2c-ffa6-41f3-bdf6-ad3d3ddead86 | cli/keygen_windows_amd64_1_0_1.exe | exe      | windows/amd64   |
      | 4aae91f5-b357-45f9-a691-d415d98a9807 | cli/keygen_windows_386_1_0_1.exe   | exe      | windows/386     |
      | e96a1898-af51-43a8-8b48-71448c419558 | cli/keygen_openbsd_mips64_1_0_1    | bin      | openbsd/mips64  |
      | a45c089b-1ade-4dc5-95c3-0d58fe592e05 | cli/keygen_openbsd_arm64_1_0_1     | bin      | openbsd/arm64   |
      | d25b4f7e-0e3f-45fd-9cd8-08a6151ce255 | cli/keygen_openbsd_arm_1_0_1       | bin      | openbsd/arm     |
      | a40edf5c-8381-44bd-85be-43d0004a3c01 | cli/keygen_openbsd_amd64_1_0_1     | bin      | openbsd/amd64   |
      | 3173f542-309f-4055-8faa-61bd26ef81a3 | cli/keygen_openbsd_386_1_0_1       | bin      | openbsd/386     |
      | 472f06c7-a7f8-4807-978c-caaf017030ef | cli/keygen_netbsd_arm64_1_0_1      | bin      | netbsd/arm64    |
      | 18a54a9b-732a-4589-8d75-fada7216659a | cli/keygen_netbsd_arm_1_0_1        | bin      | netbsd/arm      |
      | fe9b3eaa-e6a0-4491-96a9-09de21213b91 | cli/keygen_netbsd_amd64_1_0_1      | bin      | netbsd/amd64    |
      | c1483ef7-24da-4b30-bcbc-c24b0c46d98c | cli/keygen_netbsd_386_1_0_1        | bin      | netbsd/386      |
      | fe23cb05-cbef-4a28-8f48-31dfcad28f65 | cli/keygen_linux_s390x_1_0_1       | bin      | linux/s390x     |
      | aebfbb06-bd9f-4cd8-b963-cf5ddb614cf7 | cli/keygen_linux_ppc64le_1_0_1     | bin      | linux/ppc64le   |
      | 60beb8bd-193e-48e7-8475-bb3bd2f52cc3 | cli/keygen_linux_ppc64_1_0_1       | bin      | linux/ppc64     |
      | de8ef48c-1e28-442a-a8ab-39c0b45affc5 | cli/keygen_linux_mipsle_1_0_1      | bin      | linux/mipsle    |
      | 0ad0c51e-0f88-47a9-9b62-ce40872a5f49 | cli/keygen_linux_mips64le_1_0_1    | bin      | linux/mips64le  |
      | 346525f7-86b8-428f-91bf-ab361799cb11 | cli/keygen_linux_mips64_1_0_1      | bin      | linux/mips64    |
      | f0b5d54b-27e0-4962-8051-19cea48a3c16 | cli/keygen_linux_mips_1_0_1        | bin      | linux/mips      |
      | af061772-c2e3-43a2-a6e8-f9ed15af1e2e | cli/keygen_linux_arm64_1_0_1       | bin      | linux/arm64     |
      | 19712632-4490-499e-8f3b-6f222306aaed | cli/keygen_linux_arm_1_0_1         | bin      | linux/arm       |
      | 38e1621f-e4ef-4c08-8724-8cb2d909c2ae | cli/keygen_linux_amd64_1_0_1       | bin      | linux/amd64     |
      | 6d47d326-b13e-4825-973b-22c1ac11dfca | cli/keygen_linux_386_1_0_1         | bin      | linux/386       |
      | a1ba77c9-0a29-4466-b0bd-6c16a77ccd77 | cli/keygen_freebsd_arm64_1_0_1     | bin      | freebsd/arm64   |
      | 4eeb44be-be26-411c-8376-51b9e74e152a | cli/keygen_freebsd_arm_1_0_1       | bin      | freebsd/arm     |
      | 78b4101a-b255-4edd-be7a-796330a6ebab | cli/keygen_freebsd_amd64_1_0_1     | bin      | freebsd/amd64   |
      | 295cee65-a2a2-4a24-a315-2e9624e064ed | cli/keygen_freebsd_386_1_0_1       | bin      | freebsd/386     |
      | 151eff1b-24ab-4b10-848f-662be052ed37 | cli/keygen_dragonfly_amd64_1_0_1   | bin      | dragonfly/amd64 |
      | d59c45bc-bab1-4dda-9e08-25a2246c4d71 | cli/keygen_darwin_arm64_1_0_1      | bin      | darwin/arm64    |
      | 92bdc5de-4a4f-493a-9fad-18e14c29a2ad | cli/keygen_darwin_amd64_1_0_1      | bin      | darwin/amd64    |
      | 67be74d9-99ff-4279-b150-14323d2b9a85 | cli/keygen_windows_arm64_1_0_1.exe | exe      | windows/arm64   |
      | 98d6681d-34c6-4aae-b4bd-3e239868c746 | cli/keygen_windows_arm_1_0_1.exe   | exe      | windows/arm     |
      | 95dba803-3f63-459b-a0e5-0b973fa86bed | cli/keygen_windows_amd64_1_0_1.exe | exe      | windows/amd64   |
      | 72974253-337b-4f1c-9614-04fda53819ef | cli/keygen_windows_386_1_0_1.exe   | exe      | windows/386     |
      | 258a923d-9c62-46c8-afa6-27c57794cdc1 | cli/keygen_openbsd_mips64_1_0_1    | bin      | openbsd/mips64  |
      | db234a05-bbf8-40bf-b7fb-c1e909042f95 | cli/keygen_openbsd_arm64_1_0_1     | bin      | openbsd/arm64   |
      | a75a1a64-268a-48d8-bdd4-7bfa7e4022d6 | cli/keygen_openbsd_arm_1_0_1       | bin      | openbsd/arm     |
      | 9bad932d-760b-4876-8b33-0e80ff8e017c | cli/keygen_openbsd_amd64_1_0_1     | bin      | openbsd/amd64   |
      | 45657f1a-b376-4478-b42a-a9d538645b4c | cli/keygen_openbsd_386_1_0_1       | bin      | openbsd/386     |
      | a39a060c-47a0-4fcf-a043-568e0a871cf1 | cli/keygen_netbsd_arm64_1_0_1      | bin      | netbsd/arm64    |
      | 2c1d5af7-a522-43e2-b334-9fada4f80e7e | cli/keygen_netbsd_arm_1_0_1        | bin      | netbsd/arm      |
      | dfb38a19-14ac-48a0-8509-b5ca4af94ce6 | cli/keygen_netbsd_amd64_1_0_1      | bin      | netbsd/amd64    |
      | d005cc2c-d30d-4720-b7e5-5af9ea3f4bdc | cli/keygen_netbsd_386_1_0_1        | bin      | netbsd/386      |
      | 7e90e520-0438-46c4-80ca-0ac10c4573ba | cli/keygen_linux_s390x_1_0_1       | bin      | linux/s390x     |
      | 6bd8b3e9-e6d2-4ab1-98a6-882602222802 | cli/keygen_linux_ppc64le_1_0_1     | bin      | linux/ppc64le   |
      | 9510866e-e548-4f4e-b833-371d64f663cf | cli/keygen_linux_ppc64_1_0_1       | bin      | linux/ppc64     |
      | 287579a0-ed77-40c7-b3a1-6bc138ee12ab | cli/keygen_linux_mipsle_1_0_1      | bin      | linux/mipsle    |
      | d4c5596f-94eb-4a8c-a302-5d58753ae3c8 | cli/keygen_linux_mips64le_1_0_1    | bin      | linux/mips64le  |
      | f417d870-4260-4562-bfc1-81feef49b191 | cli/keygen_linux_mips64_1_0_1      | bin      | linux/mips64    |
      | e87e4109-34b4-483b-9704-7bae3c867b72 | cli/keygen_linux_mips_1_0_1        | bin      | linux/mips      |
      | 05235b88-960d-481a-83f8-cb2887c035ce | cli/keygen_linux_arm64_1_0_1       | bin      | linux/arm64     |
      | 2e110690-ec48-48b9-8f06-71875ec23f5a | cli/keygen_linux_arm_1_0_1         | bin      | linux/arm       |
      | 41de93b6-5829-4299-a49c-f8d2ffd6d7eb | cli/keygen_linux_amd64_1_0_1       | bin      | linux/amd64     |
      | c6fc1988-9584-41fd-9681-414f87532386 | cli/keygen_linux_386_1_0_1         | bin      | linux/386       |
      | 5467af91-d88e-4b43-923c-a959a2b40be4 | cli/keygen_freebsd_arm64_1_0_1     | bin      | freebsd/arm64   |
      | ad5d7877-ce82-486f-8029-b67a4e053bb2 | cli/keygen_freebsd_arm_1_0_1       | bin      | freebsd/arm     |
      | 22065903-85a3-4760-b3ea-1f162e08956d | cli/keygen_freebsd_amd64_1_0_1     | bin      | freebsd/amd64   |
      | a3789fc0-c9d5-472b-8900-47f2639f4aa0 | cli/keygen_freebsd_386_1_0_1       | bin      | freebsd/386     |
      | 29e77342-233a-4cf6-abc6-e6d9d9b357e1 | cli/keygen_dragonfly_amd64_1_0_1   | bin      | dragonfly/amd64 |
      | b17b67f8-6d50-46cd-b845-99219d0fa4af | cli/keygen_darwin_arm64_1_0_1      | bin      | darwin/arm64    |
      | 4d5e23f8-bb32-4518-8dc2-7b2f8154d2ca | cli/keygen_darwin_amd64_1_0_1      | bin      | darwin/amd64    |
      | 13d349ff-1cc9-42e5-8e5c-72b9b9e6b4a7 | cli/version                        | txt      |                 |
      | 840a0bf2-6bf5-4c1a-917f-26b289266202 | cli/install.sh                     | sh       |                 |
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?version=1.0.1&limit=100"
    Then the response status should be "200"
    And the JSON response should be an array with 33 "releases"
    And the JSON data should be ordered by "created_at"

  Scenario: Admin retrieves all tar.gz releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?filetype=tar.gz"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "releases"

  Scenario: Admin retrieves all exe releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?filetype=exe"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "releases"

  Scenario: Admin retrieves all dmg releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?filetype=dmg&channel=alpha"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "releases"

  Scenario: Admin retrieves all macos releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?platform=macos&channel=beta"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "releases"

  Scenario: Admin retrieves all win32 releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?platform=win32&channel=stable"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "release"

  Scenario: Admin retrieves all linux releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?platform=linux"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "releases"

  Scenario: Admin retrieves all win32 beta releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-beta.2.exe | exe      | win32    |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?channel=beta&platform=win32"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "releases"

  Scenario: Admin retrieves all x86 releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg        | dmg      | macos    | x86  |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg        | dmg      | macos    | x86  |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg        | dmg      | macos    | x86  |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | x86  |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-beta.1.exe | exe      | win32    | x64  |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-beta.2.exe | exe      | win32    | x86  |
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?arch=x64"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "release"
