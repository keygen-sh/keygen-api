@api/v1
Feature: Update key

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin updates a key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "key"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/keys/$0" with the following:
      """
      {
        "data": {
          "type": "keys",
          "id": "$keys[0].id",
          "attributes": {
            "key": "KTDCQ3RmtKaYewE2LpEtpbjrHwF6jB"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "key" with the key "KTDCQ3RmtKaYewE2LpEtpbjrHwF6jB"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin updates a key's policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "policy"
    And the current account has 1 "key"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/keys/$0" with the following:
      """
      {
        "data": {
          "type": "keys",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product updates a key for their product
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "key"
    And the current product has 1 "key"
    When I send a PATCH request to "/accounts/test1/keys/$0" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "b7WEYVoRjUBcd6WkYoPoMuoN4QbCpi"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "key" with the key "b7WEYVoRjUBcd6WkYoPoMuoN4QbCpi"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product attempts to update a key for another product
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "key"
    When I send a PATCH request to "/accounts/test1/keys/$0" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "Xh69xdPCfDR8KnjgCYPsGREdJMkvkD"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User attempts to update a key for their account
    Given the current account is "test1"
    And the current account has 3 "webhookEndpoints"
    And the current account has 3 "keys"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/keys/$0" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "ro4eusvzGsdkMBo7pzyyZsAV4tYuvU"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous user attempts to update a key for their account
    Given the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 3 "keys"
    When I send a PATCH request to "/accounts/test1/keys/$0" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "JoTX8VtoVhGyUoz7mfATgZh6nsnWPB"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to update a key for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/keys/$0" with the following:
      """
      {
        "data": {
          "type": "keys",
          "attributes": {
            "key": "X7jsEKVwYgJ6CJGjqCgXARq7tWkqNZ"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
