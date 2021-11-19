@api/v1
Feature: Short bin URLs

  Background:
    Given the following "accounts" exist:
      | Name    | Slug   |
      | Keygen  | keygen |
    And I send and accept JSON

  Scenario: Subdomain 'bin' should redirect to an artifact
    When I send a GET request to "//bin.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "307"
    Then the response should contain the following headers:
      """
      { "Location": "/v1/accounts/keygen/artifacts/cli%2Finstall.sh" }
      """

  Scenario: Subdomain 'get' should redirect to an artifact
    When I send a GET request to "//get.keygen.sh/keygen/cli/install.sh"
    Then the response status should be "307"
    Then the response should contain the following headers:
      """
      { "Location": "/v1/accounts/keygen/artifacts/cli%2Finstall.sh" }
      """
