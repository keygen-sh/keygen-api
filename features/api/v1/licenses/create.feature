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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a named license for a user of their account
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
            "name": "Some License Name"
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
    And the JSON response should be a "license" with the name "Some License Name"
    And the response should contain a valid signature header for "test1"
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
              "exampleKey3": 3,
              "example key 4": 4
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
          "exampleKey3": 3,
          "exampleKey4": 4
        }
      }
      """
    And the current account should have 1 "license"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a legacy encrypted license for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "LEGACY_ENCRYPT",
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
    And the JSON response should be a "license" with the scheme "LEGACY_ENCRYPT"
    And the JSON response should be a "license" that is encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a legacy encrypted license with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "LEGACY_ENCRYPT",
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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_ENCRYPT for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_ENCRYPT"
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
        "detail": "must be specified for a license using RSA_2048_PKCS1_ENCRYPT",
        "code": "KEY_BLANK",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_ENCRYPT with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_ENCRYPT"
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
    And the JSON response should be a "license" with the encrypted key "some-encrypted-payload-here" using "RSA_2048_PKCS1_ENCRYPT"
    And the JSON response should be a "license" with the scheme "RSA_2048_PKCS1_ENCRYPT"
    And the JSON response should be a "license" that is not encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_ENCRYPT with a key that is too large
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_ENCRYPT"
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
            "key": "some-payload-that-is-too-large-for-encrypting-with-rsa-2048-3dd00576de47b1994e893e5ad0fd9365a574afaff388d8c8363546fa537ac6806b834be964b1ae5ae4aea3650ec8e7c3a65a014a80b82ad71242ae8946bddcba6b6744b01b570d791f605ee5ae5ce06d1f13846119da9efb3da4461d2acf31ff0d624de3b50c621629a979cca9865aa195e89b47beed3d4804aa3ee3a237ddfab7a67905282117d1b34b023ce3ff6518b2fd729547e5a7fae65b6094ba94bf5a768ff4bf668ecc8bb17e5458bc8e36982bc3a366f7560a9d266aa1ad391fe84cad07c92283858cf42a460a1f83450b376b0b58089288cc918991909586d8726a94f0075fdc76e383556be744748991d48cf87aff3a"
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
        "detail": "key exceeds maximum byte length (max size of 245 bytes)",
        "code": "KEY_BYTE_SIZE_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_SIGN for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_SIGN"
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
        "detail": "must be specified for a license using RSA_2048_PKCS1_SIGN",
        "code": "KEY_BLANK",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_SIGN with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_SIGN"
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
    And the JSON response should be a "license" with the signed key of "some-signed-payload-here" using "RSA_2048_PKCS1_SIGN"
    And the JSON response should be a "license" with the scheme "RSA_2048_PKCS1_SIGN"
    And the JSON response should be a "license" that is not encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN"
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
        "detail": "must be specified for a license using RSA_2048_PKCS1_PSS_SIGN",
        "code": "KEY_BLANK",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_PKCS1_PSS_SIGN with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_PKCS1_PSS_SIGN"
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
    And the JSON response should be a "license" with the signed key of "some-signed-payload-here" using "RSA_2048_PKCS1_PSS_SIGN"
    And the JSON response should be a "license" with the scheme "RSA_2048_PKCS1_PSS_SIGN"
    And the JSON response should be a "license" that is not encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 for a user of their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_JWT_RS256"
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
        "detail": "must be specified for a license using RSA_2048_JWT_RS256",
        "code": "KEY_BLANK",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 with an invalid payload
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_JWT_RS256"
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
            "key": "some-non-json-payload"
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
        "detail": "key is not a valid JWT claims payload (must be a valid JSON encoded string)",
        "code": "KEY_JWT_CLAIMS_INVALID",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 with an invalid JWT exp
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_JWT_RS256"
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
            "key": "{\"exp\":\"foo\"}"
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
        "detail": "key is not a valid JWT claims payload (exp claim must be an integer)",
        "code": "KEY_JWT_CLAIMS_INVALID",
        "source": {
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a license using scheme RSA_2048_JWT_RS256 with a pre-determined key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": []
      }
      """
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "scheme": "RSA_2048_JWT_RS256"
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
            "key": "{ \"exp\": 4691671952 }"
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
    And the JSON response should be a "license" with the jwt key '{ "exp": 4691671952 }' using "RSA_2048_JWT_RS256"
    And the JSON response should be a "license" with the scheme "RSA_2048_JWT_RS256"
    And the JSON response should be a "license" that is not encrypted
    And the JSON response should be a "license" that is not strict
    And the JSON response should be a "license" that is not floating
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

  Scenario: User creates an unprotected license for themself
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
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: protected"
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a protected license for themself
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
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: protected"
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a suspended license for themself
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
          "attributes": {
            "suspended": true
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
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: suspended"
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates a license for themself with a pre-determined expiry
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
          "attributes": {
            "expiry": "2099-09-01T22:53:37.000Z"
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
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: expiry"
      }
      """
    And the current account should have 0 "licenses"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

  Scenario: Admin uses an invalid token that looks like a UUID while attempting to create a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And I send the following headers:
      """
      {
        "Authorization": "Bearer 852da78f-1444-4462-8863-d7b9fff9e003",
        "Origin": "https://app.keygen.sh"
      }
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
    And sidekiq should have 0 "request-log" jobs

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 0 "request-log" jobs
