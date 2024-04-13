@api/v1
Feature: Yank release

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
    And the current account has 1 "release"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "403"

  Scenario: Admin yanks a draft release for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "status": "YANKED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin yanks a published release for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 published "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "status": "YANKED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin yanks a yanked release for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 yanked "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "status": "YANKED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment publishes an isolated release
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "status": "YANKED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product yanks a release
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "status": "YANKED" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product yanks a release for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License yanks a release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "404"

  Scenario: License yanks a release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "403"

  Scenario: User yanks a release without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "license" for the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "404"

  Scenario: User yanks a release with a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "403"

  Scenario: Anonymous yanks a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    When I send a POST request to "/accounts/test1/releases/$0/actions/yank"
    Then the response status should be "401"
