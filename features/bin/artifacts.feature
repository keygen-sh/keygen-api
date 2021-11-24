@api/v1
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
    And the first "release" has the following attributes:
      """
      { "filename": "cli/install.sh" }
      """
    And the first "release" has an artifact that is uploaded

  Scenario: Subdomain 'bin' should redirect to an artifact
    When I send a GET request to "//bin.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "303"

  Scenario: Subdomain 'get' should redirect to an artifact
    When I send a GET request to "//get.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "303"
