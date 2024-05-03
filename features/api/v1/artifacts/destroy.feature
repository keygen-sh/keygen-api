@api/v1
Feature: Delete artifact

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the last "release"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"

  Scenario: Admin deletes one of their artifacts
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$2"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their artifacts by filename (for latest release)
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-01-01T00:00:00Z | 1.0.0   | stable  |
      | a391f935-bd9b-4277-affd-16759d84d65e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-04-01T00:00:00Z | 1.1.0   | stable  |
      | 306aae31-e07d-4769-a409-518d3d2a4b10 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-02-01T00:00:00Z | 2.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | created_at           | filename              | filetype | platform | status   |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 2024-01-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
      | a391f935-bd9b-4277-affd-16759d84d65e | 2024-04-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
      | 306aae31-e07d-4769-a409-518d3d2a4b10 | 2024-02-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/dir/test.tar.gz"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And the first "artifact" should have the following attributes:
      """
      { "releaseId": "f14ef993-f821-44c9-b2af-62e27f37f8db" }
      """
    And the second "artifact" should have the following attributes:
      """
      { "releaseId": "a391f935-bd9b-4277-affd-16759d84d65e" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their artifacts by filename (for release by version)
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-01-01T00:00:00Z | 1.0.0   | stable  |
      | a391f935-bd9b-4277-affd-16759d84d65e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-04-01T00:00:00Z | 1.1.0   | stable  |
      | 306aae31-e07d-4769-a409-518d3d2a4b10 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-02-01T00:00:00Z | 2.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | created_at           | filename              | filetype | platform | status   |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 2024-01-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
      | a391f935-bd9b-4277-affd-16759d84d65e | 2024-04-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
      | 306aae31-e07d-4769-a409-518d3d2a4b10 | 2024-02-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/dir/test.tar.gz?release=1.0.0"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And the first "artifact" should have the following attributes:
      """
      { "releaseId": "306aae31-e07d-4769-a409-518d3d2a4b10" }
      """
    And the second "artifact" should have the following attributes:
      """
      { "releaseId": "a391f935-bd9b-4277-affd-16759d84d65e" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their artifacts by filename (for release by ID)
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-01-01T00:00:00Z | 1.0.0   | stable  |
      | a391f935-bd9b-4277-affd-16759d84d65e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-04-01T00:00:00Z | 1.1.0   | stable  |
      | 306aae31-e07d-4769-a409-518d3d2a4b10 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2024-02-01T00:00:00Z | 2.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | created_at           | filename              | filetype | platform | status   |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 2024-01-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
      | a391f935-bd9b-4277-affd-16759d84d65e | 2024-04-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
      | 306aae31-e07d-4769-a409-518d3d2a4b10 | 2024-02-01T00:00:00Z | dir/test.tar.gz | tar.gz   | linux    | UPLOADED |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/dir/test.tar.gz?release=a391f935-bd9b-4277-affd-16759d84d65e"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And the first "artifact" should have the following attributes:
      """
      { "releaseId": "f14ef993-f821-44c9-b2af-62e27f37f8db" }
      """
    And the second "artifact" should have the following attributes:
      """
      { "releaseId": "306aae31-e07d-4769-a409-518d3d2a4b10" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin deletes one of their artifacts (S3 timing out)
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And AWS S3 is timing out
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "204"
    And the current account should have 3 "artifacts"
    And the first "artifact" should have the following attributes:
      """
      { "status": "YANKED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to delete an artifact for another account
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$1"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "artifacts"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer deletes one of their artifacts
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "developer"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales deletes one of their artifacts
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$1"
    Then the response status should be "403"

  Scenario: Support deletes one of their releases
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$2"
    Then the response status should be "403"

  Scenario: Read-only deletes one of their artifacts
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$1"
    Then the response status should be "403"

  @ee
  Scenario: Environment deletes an artifact (isolated)
    Given the current account is "test1"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "artifacts"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment deletes an artifact (shared)
    Given the current account is "test1"
    And the current account has 2 shared "webhook-endpoints"
    And the current account has 1 shared "environment"
    And the current account has 3 shared "artifacts"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes one of their artifacts
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for the first "product"
    And the current account has 3 "artifacts" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "204"
    And the current account should have 2 "artifacts"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product deletes an artifact for a different product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the current account has 3 "artifacts" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"
    And the current account should have 3 "artifacts"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to delete an artifact for their product
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "artifacts" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"

  Scenario: User attempts to delete an artifact for their product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And the current account has 4 "releases" for the last "product"
    And the current account has 3 "artifacts" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/artifacts/$1"
    Then the response status should be "403"

  Scenario: Anonymous attempts to delete an artifact
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "release"
    And the current account has 3 "artifacts" for the last "release"
    When I send a DELETE request to "/accounts/test1/artifacts/$0"
    Then the response status should be "401"
