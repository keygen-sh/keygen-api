@api/v1.0 @deprecated
@mp
Feature: Short bin URLs
  Background:
    Given the following "accounts" exist:
      | Name    | Slug   |
      | Keygen  | keygen |
    And I send and accept JSON
    And the current account is "keygen"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And the first "artifact" has the following attributes:
      """
      { "filename": "cli/install.sh" }
      """

  Scenario: Endpoint should be inaccessible when account is using >= v1.1
    And I use API version "1.1"
    When I send a GET request to "//get.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "404"

  Scenario: Subdomain 'bin' should redirect to an artifact
    And I use API version "1.0"
    When I send a GET request to "//bin.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "303"

  Scenario: Subdomain 'get' should redirect to an artifact
    And I use API version "1.0"
    When I send a GET request to "//get.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "303"

  Scenario: Subdomain 'get' should support any accept header
    And I use API version "1.0"
    And I send the following headers:
      """
      { "Accept": "text/*" }
      """
    When I send a GET request to "//get.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "303"
