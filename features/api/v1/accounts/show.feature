@api/v1
Feature: Show account

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1"
    Then the response status should not be "403"

  Scenario: Admin retrieves their account
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    And the JSON response should be an "account"
    And the JSON response should be an "account" with the following meta:
      """
      { "publicKey": "$~accounts[0].public_key" }
      """
    And sidekiq should have 1 "log" job

  Scenario: Admin attempts to retrieve another account
    Given I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And sidekiq should have 1 "log" job

  Scenario: User attempts to retrieve an account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1"
    Then the response status should be "403"
    And sidekiq should have 1 "log" job

  Scenario: User attempts to retrieve an invalid account
    Given the account "test1" has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/invalid"
    Then the response status should be "404"

  Scenario: Admin retrieves their account, accepting no content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": null }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting any content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "*/*" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting any content-type with metadata
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      # This is the accept header Stripe sends us
      """
      { "Accept": "*/*; q=0.5, application/xml" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting JSONAPI content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/vnd.api+json" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json" }
      """

  Scenario: Admin retrieves their account, accepting JSON content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/json" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "200"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/json" }
      """

  Scenario: Admin retrieves their account, accepting XML content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/xml" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"

  Scenario: Admin retrieves their account, accepting HTML content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "text/html" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"

  Scenario: Admin retrieves their account, accepting plain-text content-type
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "text/plain" }
      """
    When I send a GET request to "/accounts/test1"
    Then the response status should be "400"
