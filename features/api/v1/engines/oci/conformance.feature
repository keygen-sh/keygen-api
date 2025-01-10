@api/v1
@ee
Feature: OCI spec conformance
  Background:
    Given the following "accounts" exist:
      | id                                   | slug      | name      |
      | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | linux     | Linux     |
      | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | keygen    | Keygen    |
      | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | microsoft | Microsoft |
    And the following "products" exist:
      | id                                   | account_id                           | code    | name         | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | alpine  | Alpine Linux | OPEN                  |
      | 54dbf634-ba9a-44ca-9f2d-f69405bb139c | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | ubuntu  | Ubuntu Linux | LICENSED              |
      | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | keygen  | Keygen       | LICENSED              |
      | b753b26a-836a-410f-9b3d-74a95d27dbc0 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | windows | Windows      | CLOSED                |
    And the following "packages" exist:
      | id                                   | account_id                           | product_id                           | engine | key       | created_at               | updated_at               |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 6198261a-48b5-4445-a045-9fed4afc7735 | oci    | alpine    | 2024-11-01T01:23:45.000Z | 2024-11-01T01:23:45.000Z |
      | ba6a3950-4f18-468f-97af-8706f84d5bfb | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 54dbf634-ba9a-44ca-9f2d-f69405bb139c | oci    | ubuntu    | 2024-11-02T01:23:45.000Z | 2024-11-02T01:23:45.000Z |
      | a81a0707-7ef2-417e-8597-ebedba6508ac | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | oci    | api       | 2024-11-0T001:23:45.000Z | 2024-11-03T01:23:45.000Z |
      | 09b859da-d026-414e-a5c0-3ac756da706c | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | b753b26a-836a-410f-9b3d-74a95d27dbc0 | oci    | windows   | 2024-11-0T001:23:45.000Z | 2024-11-03T01:23:45.000Z |
    And the current account is "linux"
    And I send the following raw headers:
      """
      User-Agent: docker/27.0.3 go/go1.21.11 git-commit/662f78c kernel/5.15.153.1-microsoft-standard-WSL2 os/linux arch/amd64 containerd-client/1.7.18+unknown storage-driver/overlayfs UpstreamClient(Docker-Client/27.0.3 \(linux\))
      Accept: */*
      """

  Scenario: Endpoint should pass conformance ack (trailing slash)
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "//oci.pkg.keygen.sh/v2/"
    Then the response status should be "200"

  Scenario: Endpoint should pass conformance ack (no slash)
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "//oci.pkg.keygen.sh/v2"
    Then the response status should be "200"

  @mp
  Scenario: Endpoint should fail referrers
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "//oci.pkg.keygen.sh/v2/linux/alpine/referrers/foo"
    Then the response status should be "405"

  @mp
  Scenario: Endpoint should fail upload
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a POST request to "//oci.pkg.keygen.sh/v2/linux/alpine/blobs/uploads"
    Then the response status should be "405"

  @mp
  Scenario: Endpoint should fail yank
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a DELETE request to "//oci.pkg.keygen.sh/v2/linux/alpine/manifests/3.20.2"
    Then the response status should be "405"

  @sp
  Scenario: Endpoint should fail referrers
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "//oci.pkg.keygen.sh/v2/alpine/referrers/foo"
    Then the response status should be "405"

  @sp
  Scenario: Endpoint should fail upload
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a POST request to "//oci.pkg.keygen.sh/v2/alpine/blobs/uploads"
    Then the response status should be "405"

  @sp
  Scenario: Endpoint should fail yank
    Given I am an admin of account "linux"
    And I use an authentication token
    When I send a DELETE request to "//oci.pkg.keygen.sh/v2/alpine/manifests/3.20.2"
    Then the response status should be "405"
