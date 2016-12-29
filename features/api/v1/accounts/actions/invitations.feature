@api/v1
Feature: Account invitation actions

  Background:
    Given the following "accounts" exist:
      | Name   | Slug  |
      | Tesla  | tesla |
    And I send and accept JSON

  Scenario: Anonymous accepts an invitation for an account
    Given the account "tesla" has been invited
    And the account "tesla" has the following attributes:
      """
      { "inviteToken": "\$2a\$10\$KW.pA/mao7GeXL4iihG3hOev7SjcfqFY9/o/Ct52LJ7CiCFmGUotm" }
      """
    When I send a POST request to "/accounts/tesla/actions/accept-invitation" with the following:
      """
      { "meta": { "inviteToken": "token" } }
      """
    Then the response status should be "202"
    And the account "tesla" should have the following attributes:
      """
      { "inviteState": "accepted" }
      """
    And the account should receive a "beta invitation" email

  Scenario: Anonymous accepts an invitation for an account that has already accepted
    Given the account "tesla" has accepted an invitation
    And the account "tesla" has the following attributes:
      """
      { "inviteToken": "\$2a\$10\$KW.pA/mao7GeXL4iihG3hOev7SjcfqFY9/o/Ct52LJ7CiCFmGUotm" }
      """
    When I send a POST request to "/accounts/tesla/actions/accept-invitation" with the following:
      """
      { "meta": { "inviteToken": "token" } }
      """
    Then the response status should be "409"
    And the account "tesla" should have the following attributes:
      """
      { "inviteState": "accepted" }
      """
    And the account should not receive a "beta invitation" email

  Scenario: Anonymous uses an invalid invitation token for an account
    Given the account "tesla" has been invited
    And the account "tesla" has the following attributes:
      """
      { "inviteToken": "\$2a\$10\$KW.pA/mao7GeXL4iihG3hOev7SjcfqFY9/o/Ct52LJ7CiCFmGUotm" }
      """
    When I send a POST request to "/accounts/tesla/actions/accept-invitation" with the following:
      """
      { "meta": { "inviteToken": "someInvalidToken" } }
      """
    Then the response status should be "422"
    And the account "tesla" should have the following attributes:
      """
      { "inviteState": "invited" }
      """
    And the account should not receive a "beta invitation" email

  Scenario: Anonymous accepts an invitation to nothing … because they weren't invited
    Given the account "tesla" has not been invited
    And the account "tesla" has the following attributes:
      """
      { "inviteToken": "\$2a\$10\$KW.pA/mao7GeXL4iihG3hOev7SjcfqFY9/o/Ct52LJ7CiCFmGUotm" }
      """
    When I send a POST request to "/accounts/tesla/actions/accept-invitation" with the following:
      """
      { "meta": { "inviteToken": "token" } }
      """
    Then the response status should be "422"
    And the account "tesla" should have the following attributes:
      """
      { "inviteState": "uninvited" }
      """
    And the account should not receive a "beta invitation" email
