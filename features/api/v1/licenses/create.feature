@api/v1
Feature: Create license

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses"
    Then the response status should be "403"

  Scenario: Admin creates a license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  # Scenario: Admin creates a license for a user of their account with a key that contains a null byte
  #   Given I am an admin of account "test1"
  #   And the current account is "test1"
  #   And the current account has 1 "webhook-endpoint"
  #   And the current account has 1 "policies"
  #   And the current account has 1 "user"
  #   And I use an authentication token
  #   When I send a POST request to "/accounts/test1/licenses" with the following:
  #     """
  #     {
  #       "data": {
  #         "type": "licenses",
  #         "attributes": {
  #           "key": "$null_byte"
  #         },
  #         "relationships": {
  #           "policy": {
  #             "data": {
  #               "type": "policies",
  #               "id": "$policies[0]"
  #             }
  #           },
  #           "user": {
  #             "data": {
  #               "type": "users",
  #               "id": "$users[1]"
  #             }
  #           }
  #         }
  #       }
  #     }
  #     """
  #   Then the response status should be "400"
  #   And the current account should have 0 "licenses"
  #   And sidekiq should have 0 "webhook" jobs
  #   And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license with an invalid policy for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "4796e950-0dcf-4bab-9443-8b406889356e"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "POLICY_BLANK",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license for an invalid user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "4796e950-0dcf-4bab-9443-8b406889356e"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "USER_BLANK",
        "source": {
          "pointer": "/data/relationships/user"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license with metadata for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "fooBarBaz": "Qux"
            }
          },
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
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "license" with the following attributes:
      """
      {
        "metadata": {
          "fooBarBaz": "Qux"
        }
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a license with metadata for their account and the keys should be transformed to camelcase
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "metadata": {
              "example_key_1": 1,
              "ExampleKey2": 2,
              "exampleKey3": 3
            }
          },
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
    Then the response status should be "201"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "license" with the following attributes:
      """
      {
        "metadata": {
          "exampleKey1": 1,
          "exampleKey2": 2,
          "exampleKey3": 3
        }
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a license with a pre-determined expiry
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z"
          },
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
    Then the response status should be "201"
    And the JSON response should be a "license" with an expiry "2016-09-05T22:53:37.000Z"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
          },
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
    Then the response status should be "201"
    And the JSON response should be a "license" with the key "a"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a duplicate license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "key": "a"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
          },
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
    Then the response status should be "422"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license with a pre-determined key that conflicts with a license ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "$licenses[2].id"
          },
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
    Then the response status should be "422"
    And the current account should have 3 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a duplicate license of another account with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the account "test2" has 1 "policy"
    And the account "test2" has 1 "license"
    And the first "license" of account "test2" has the following attributes:
      """
      {
        "key": "a"
      }
      """
    And the current account has 1 "policy"
    And the first "policy" of account "test1" has the following attributes:
      """
      { "maxMachines": 3 }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
          },
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
    Then the response status should be "201"
    And the JSON response should be a "license" with maxMachines "3"
    And the JSON response should be a "license" with the key "a"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 1 "metric" jobs

  Scenario: Admin creates a legacy encrypted license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "LEGACY",
        "encrypted": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" with the encryptionScheme "LEGACY"
    And the JSON response should be a "license" that is encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a legacy encrypted license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "LEGACY",
        "encrypted": true,
        "strict": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot be specified for a legacy encrypted license",
        "code": "KEY_NOT_SUPPORTED",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates an RSA encrypted license using RSA_2048_ENCRYPT for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "RSA_2048_ENCRYPT",
        "encrypted": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
     Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be specified for an encrypted license using RSA_2048_ENCRYPT",
        "code": "KEY_BLANK",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates an RSA encrypted license using RSA_2048_ENCRYPT with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "RSA_2048_ENCRYPT",
        "encrypted": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-encrypted-payload-here"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" with the encrypted key "some-encrypted-payload-here" using "RSA_2048_ENCRYPT"
    And the JSON response should be a "license" with the encryptionScheme "RSA_2048_ENCRYPT"
    And the JSON response should be a "license" that is encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates an RSA encrypted license using RSA_2048_SIGN for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "RSA_2048_SIGN",
        "encrypted": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
     Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the JSON response should be an array of 2 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be specified for an encrypted license using RSA_2048_SIGN",
        "code": "KEY_BLANK",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And the second error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "failed to generate key signature",
        "source": {
          "pointer": "/data/attributes/signature"
        },
        "code": "SIGNATURE_BLANK"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates an RSA encrypted license using RSA_2048_SIGN with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "encryptionScheme": "RSA_2048_SIGN",
        "encrypted": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "some-signed-payload-here"
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" with the encrypted signature of "some-signed-payload-here" using "RSA_2048_SIGN"
    And the JSON response should be a "license" with the encryptionScheme "RSA_2048_SIGN"
    And the JSON response should be a "license" that is encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a license without a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
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
    Then the response status should be "201"
    And the JSON response should be a "license" that is not protected
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a license with a null user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": null
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin attempts to create a license without a policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title":"Bad request",
        "detail": "is missing",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to create a license with an invalid policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            },
            "policy": {
              "data": {
                "type": "policies",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must exist",
        "code": "POLICY_BLANK",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license with a reserved key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "actions"
          },
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
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "is reserved",
        "code": "KEY_NOT_ALLOWED",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User creates a license for themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: User attempts to create a license without a user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
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
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User attempts to create a license for another user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license using a pooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "usePool": true,
        "strict": true
      }
      """
    And the current account has 4 "keys"
    And all "keys" have the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And the current account has 3 "users"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the current account should have 3 "keys"
    And the JSON response should be a "license" that is not floating
    And the JSON response should be a "license" that is strict
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a license with an empty policy pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "usePool": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "pool is empty",
        "code": "POLICY_POOL_EMPTY",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license for a user of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And the current account should have 0 "licenses"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin creates a license using a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" that is protected
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a protected license using a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": true
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" that is protected
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates a protected license using an unprotected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": false,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": true
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" that is protected
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin creates an unprotected license using a protected policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true,
        "floating": true
      }
      """
    And the current account has 1 "user"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "protected": false
          },
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" that is not protected
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product creates a license using a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "month",
        "checkInIntervalCount": 3,
        "protected": true
      }
      """
    And the current account has 1 "user"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the current account should have 1 "license"
    And the JSON response should be a "license" that is protected
    And the JSON response should be a "license" that is requireCheckIn
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: User creates a license using a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "protected": true
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User attempts to create a license with mismatched policy/user IDs
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$users[1]"
              }
            },
            "user": {
              "data": {
                "type": "users",
                "id": "$users[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin uses an invalid token that looks like a UUID while attempting to create a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I send the following headers:
      """
      { "Authorization": "Bearer 852da78f-1444-4462-8863-d7b9fff9e003" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
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
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "Token format is invalid (make sure the token begins with a proper prefix e.g. 'prod-XXX' or 'acti-XXX', and that it's not a token UUID)",
        "code": "TOKEN_FORMAT_INVALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin uses an invalid token while attempting to create a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I send the following headers:
      """
      { "Authorization": "Bearer prod-4TzUcN9xMV2cUVT3AuDbPx8XWXnDRF4TzUcN9xMV2cUVT3AuDbPx8XWXnDRFnReibxxgBxXaY2gpb7DRDkUmZpyYi2sXzYfyVL4buWtbgyFD9zbd1319f14b90de1cv2" }
      """
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
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
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin sends invalid JSON while attempting to create a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[0]"
              }
            }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The request could not be completed because it contains invalid JSON",
        "code": "JSON_INVALID"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
