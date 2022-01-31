@api/v1
Feature: Custom domains via CNAME

  Background:
    Given the following "accounts" exist:
      | name     | slug         | domain                |
      | Keygen   | keygen-sh    |                       |
      | Example  | example-com  | licensing.example.com |
      | ACME     | acme-example |                       |
      | Attacker | bad-example  | api.keygen.sh         |
    And I send and accept JSON

  Scenario: Admin requests their billing info using a custom domain (with path)
    Given the current account is "example-com"
    And I am an admin of account "example-com"
    And I use an authentication token
    When I send a GET request to "//licensing.example.com/v1/accounts/example-com/billing"
    Then the response status should be "404"

  Scenario: Admin requests their billing info using a custom domain (no path)
    Given the current account is "example-com"
    And I am an admin of account "example-com"
    And I use an authentication token
    When I send a GET request to "//licensing.example.com/v1/billing"
    Then the response status should be "404"

  Scenario: Anonyous sends a ping using a custom domain (with CNAME)
    Given the current account is "example-com"
    When I send a GET request to "//licensing.example.com/v1/ping"
    Then the response status should be "200"

  Scenario: Product requests their profile using a custom domain (with domain added)
    Given the current account is "example-com"
    And the current account has 1 "product"
    And I am a product of account "example-com"
    And I use an authentication token
    When I send a GET request to "//licensing.example.com/v1/me"
    Then the response status should be "200"
    And the response should contain a valid signature header for "example-com"

  Scenario: Product requests their profile using a custom domain (wrong subdomain)
    Given the current account is "example-com"
    And the current account has 1 "product"
    And I am a product of account "example-com"
    And I use an authentication token
    When I send a GET request to "//foo.example.com/v1/me"
    Then the response status should be "404"

  Scenario: Product requests their profile using a custom domain (no domain added)
    Given the current account is "acme-example"
    And the current account has 1 "product"
    And I am a product of account "acme-example"
    And I use an authentication token
    When I send a GET request to "//licensing.acme.example/v1/me"
    Then the response status should be "404"

  Scenario: Product requests their profile using a custom domain (invalid)
    Given the current account is "keygen-sh"
    And the current account has 1 "product"
    And I am a product of account "keygen-sh"
    And I use an authentication token
    When I send a GET request to "//foo.keygen.sh/v1/me"
    Then the response status should be "404"

  Scenario: Product requests their profile without an account
    When I send a GET request to "//api.keygen.sh/v1/me"
    Then the response status should be "404"
