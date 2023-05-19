@api/v1.1
@mp
Feature: Short URLs
  Background:
    Given the following "accounts" exist:
      | Name    | Slug   |
      | Keygen  | keygen |
    And the current account is "keygen"
    And the current account has the following "product" rows:
      | id                                   | name | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | CLI  | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | tag    | channel |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | latest | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename   | filetype |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | install.sh | sh       |
    And I send and accept JSON

  Scenario: Endpoint should not be accessible when account is using v1.0
    And I use API version "1.0"
    When I send a GET request to "//get.keygen.sh/keygen/latest/install.sh"
    Then the response status should be "404"

  Scenario: Endpoint should be accessible when account is using v1.1
    And I use API version "1.1"
    When I send a GET request to "//get.keygen.sh/keygen/latest/install.sh"
    Then the response status should be "303"

  Scenario: Subdomain 'get' should redirect to an artifact
    And I use API version "1.1"
    When I send a GET request to "//get.keygen.sh/keygen/latest/install.sh"
    Then the response status should be "303"

  Scenario: Subdomain 'bin' should redirect to an artifact
    And I use API version "1.1"
    When I send a GET request to "//bin.keygen.sh/keygen/latest/install.sh"
    Then the response status should be "303"

  Scenario: Subdomain 'get' should support any accept header
    And I use API version "1.1"
    And I send the following headers:
      """
      { "Accept": "text/*" }
      """
    When I send a GET request to "//get.keygen.sh/keygen/latest/install.sh"
    Then the response status should be "303"
