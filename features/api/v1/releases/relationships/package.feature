@api/v1
Feature: Release package relationship
  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  # Retrieve
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "403"

  Scenario: Admin retrieves the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "200"
    And the response body should be a "package"

  @ee
  Scenario: Environment retrieves the package for an isolated release
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And the current account has 1 isolated "package" for the last "product"
    And the current account has 1 isolated "release" for the last "product"
    And the last "release" belongs to the last "package"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Product retrieves the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Product retrieves the package for a release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "package" for the second "product"
    And the current account has 1 "release" for the second "product"
    And the last "release" belongs to the second "package"
    And I am the first product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "404"

  Scenario: License retrieves the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: License retrieves the package for a release of another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "404"

  Scenario: User retrieves the package for a release of a product (license owner)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: User retrieves the package for a release of a product (license user)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: User retrieves the package for a release of another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "404"

  Scenario: Anonymous retrieves the package for a licensed release
    Given the current account is "test1"
    And the current account has 1 licensed "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "404"

  Scenario: Anonymous retrieves the package for a closed release
    Given the current account is "test1"
    And the current account has 1 closed "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "404"

  Scenario: Anonymous retrieves the package for an open release
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Admin attempts to retrieve the package for a release of another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the last "release" belongs to the last "package"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/package"
    Then the response status should be "401"

  # Update
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/package"
    Then the response status should be "403"

  Scenario: Admin updates the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "packages" for the last "product"
    And the current account has 2 "releases" for the last "product"
    And the first "release" belongs to the first "package"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/package" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following data:
      """
      { "id": "$packages[1]" }
      """

  Scenario: Admin clears the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "packages" for the last "product"
    And the current account has 2 "releases" for the last "product"
    And the first "release" belongs to the first "package"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/package" with the following:
      """
      {
        "data": null
      }
      """
    Then the response status should be "200"
    And the response body should be the following:
      """
      { "data": null }
      """

  @ee
  Scenario: Environment updates the package for a release
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "product"
    And the current account has 1 shared "package" for the last "product"
    And the current account has 1 shared "release" for the last "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/package?environment=shared" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following data:
      """
      { "id": "$packages[0]" }
      """

  Scenario: Product updates the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/package" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "package" with the following data:
      """
      { "id": "$packages[0]" }
      """

  Scenario: License updates the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/package" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0]"
        }
      }
      """
    Then the response status should be "403"

  Scenario: User updates the package for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/package" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0]"
        }
      }
      """
    Then the response status should be "403"

  Scenario: Anonmyous updates the package for a release
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "release" for the last "product"
    When I send a PUT request to "/accounts/test1/releases/$0/package" with the following:
      """
      {
        "data": {
          "type": "packages",
          "id": "$packages[0]"
        }
      }
      """
    Then the response status should be "401"
