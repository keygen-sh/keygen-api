@api/v1
Feature: Spawn machine process

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes"
    Then the response status should be "403"
    And the current account should have 0 "processes"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for their account
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE",
        "pid": "1"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "process-heartbeat" job
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: Developer spawns a process for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Sales spawns a process for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"

  Scenario: Support attempts to spawn a process for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Read-only attempts to spawn a process for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin spawns a process for their account with a UUID pid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "977f1752-d6a9-4669-a6af-b039154ec40f"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "977f1752-d6a9-4669-a6af-b039154ec40f"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process with a pid matching another process's ID (different machine)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And the current account has 1 "process"
    And the last "process" has the following attributes:
      """
      { "pid": "1337" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process with a pid matching another process's ID (same machine)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And the current account has 1 "process" for the last "machine"
    And the last "process" has the following attributes:
      """
      { "pid": "1337" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "has already been taken",
        "code": "PID_TAKEN",
        "source": {
          "pointer": "/data/attributes/pid"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for their account with a pid matching a reserved word
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And the current account has 1 "process"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "actions"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process with missing pid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process with missing machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process with an invalid machine UUID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "n04evzjqadp9ytuo"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "16896379-73ae-4d92-a458-6e7841c9ad08"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has no limit (PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": null
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines" for the last "license"
    And the current account has 1 "process" for the first "machine"
    And the current account has 1 "process" for the second "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has no limit (PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": null
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines" for the last "license"
    And the current account has 1 "process" for the first "machine"
    And the current account has 1 "process" for the second "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has not reached its limit (PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 3
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines" for the last "license"
    And the current account has 3 "processes" for the second "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has not reached its limit (PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 8
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines" for the last "license"
    And the current account has 1 "process" for the first "machine"
    And the current account has 1 "process" for the second "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has almost reached its limit (PER_MACHINE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 10
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines" for the last "license"
    And the current account has 9 "processes" for the first "machine"
    And the current account has 1 "process" for the second "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has almost reached its limit (PER_LICENSE leasing strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 10
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And the current account has 4 "processes" for the first "machine"
    And the current account has 4 "processes" for the second "machine"
    And the current account has 1 "process" for the third "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[2]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has reached its limit (PER_MACHINE leasing strategy, NO_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_MACHINE",
        "overageStrategy": "NO_OVERAGE",
        "maxProcesses": 5
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 5 "processes" for the last "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "process count has exceeded maximum allowed for machine (5)",
        "code": "MACHINE_PROCESS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has reached its limit (PER_LICENSE leasing strategy, NO_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "leasingStrategy": "PER_LICENSE",
        "overageStrategy": "NO_OVERAGE",
        "maxProcesses": 5
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And the current account has 2 "processes" for the first "machine"
    And the current account has 2 "processes" for the second "machine"
    And the current account has 1 "processes" for the third "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "process count has exceeded maximum allowed for license (5)",
        "code": "MACHINE_PROCESS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its limit (PER_MACHINE leasing strategy, ALWAYS_ALLOW_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 5
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 7 "processes" for the last "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its limit (PER_LICENSE leasing strategy, ALWAYS_ALLOW_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALWAYS_ALLOW_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 5
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And the current account has 3 "processes" for the first "machine"
    And the current account has 2 "processes" for the second "machine"
    And the current account has 1 "processes" for the third "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its limit (PER_MACHINE leasing strategy, ALLOW_1_25X_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 20
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 23 "processes" for the last "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its overage limit (PER_MACHINE leasing strategy, ALLOW_1_25X_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_25X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 20
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 25 "processes" for the last "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "process count has exceeded maximum allowed for machine (20)",
        "code": "MACHINE_PROCESS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its limit (PER_MACHINE leasing strategy, ALLOW_1_5X_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 6
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 8 "processes" for the last "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its overage limit (PER_MACHINE leasing strategy, ALLOW_1_5X_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_1_5X_OVERAGE",
        "leasingStrategy": "PER_MACHINE",
        "maxProcesses": 6
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 9 "processes" for the last "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "process count has exceeded maximum allowed for machine (6)",
        "code": "MACHINE_PROCESS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its limit (PER_LICENSE leasing strategy, ALLOW_2X_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 5
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And the current account has 4 "processes" for the first "machine"
    And the current account has 3 "processes" for the second "machine"
    And the current account has 2 "processes" for the third "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin spawns a process for a machine that has exceeded its overage limit (PER_LICENSE leasing strategy, ALLOW_2X_OVERAGE overage strategy)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 floating "policy"
    And the first "policy" has the following attributes:
      """
      {
        "overageStrategy": "ALLOW_2X_OVERAGE",
        "leasingStrategy": "PER_LICENSE",
        "maxProcesses": 5
      }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And the current account has 5 "processes" for the first "machine"
    And the current account has 4 "processes" for the second "machine"
    And the current account has 1 "processes" for the third "machine"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "process count has exceeded maximum allowed for license (5)",
        "code": "MACHINE_PROCESS_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment spawns an isolated process for their account
    Given time is frozen at "2022-10-16T14:52:48.000Z"
    And the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the following attributes:
      """
      {
        "lastHeartbeat": "2022-10-16T14:52:48.000Z",
        "nextHeartbeat": "2022-10-16T15:02:48.000Z",
        "status": "ALIVE",
        "pid": "1"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "process-heartbeat" job
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
    And time is unfrozen

  Scenario: User spawns a process for their machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "2"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "2"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User spawns a process for their machine with a protected policy
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User spawns a process for an unprotected machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1337"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License spawns a process for their machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 floating "policy"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1337"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License spawns a process for a protected machine
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the pid "1337"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License spawns a process for their machine with a duplicate pid
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And the first "process" has the following attributes:
      """
      { "pid": "1" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "has already been taken",
        "code": "PID_TAKEN",
        "source": {
          "pointer": "/data/attributes/pid"
        }
      }
      """
    And the current account should have 1 "process"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License spawns a process for their machine with a blank pid
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": ""
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
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
        "detail": "cannot be blank",
        "source": {
          "pointer": "/data/attributes/pid"
        }
      }
      """
    And the current account should have 0 "processes"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License spawns a process for another license's machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "machines"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "2"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[1]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product spawns a process for another product's machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "1337"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User spawns a process for another user's machine
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "2"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous attempts to spawn a process
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "machine"
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "0"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin of another account attempts to spawn a process
    Given the current account is "test1"
    And the current account has 10 "webhook-endpoints"
    And the current account has 1 "machine"
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "pid": "0"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License activates a process with a pre-determined ID
    Given the current account is "test1"
    And the current account has 1 "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "00000000-2521-4033-9f4f-3675387016f7",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "process" with the id "00000000-2521-4033-9f4f-3675387016f7"
    And the current account should have 1 "process"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job

  Scenario: License activates a process with a pre-determined ID (conflict)
    Given the current account is "test1"
    And the current account has 1 "machine"
    And the current account has 1 "process"
    And the first "process" has the following attributes:
      """
      { "id": "00000000-2521-4033-9f4f-3675387016f7" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "00000000-2521-4033-9f4f-3675387016f7",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must not conflict with another process",
        "source": {
          "pointer": "/data/id"
        },
        "code": "ID_CONFLICT"
      }
      """
    And the current account should have 1 "process"

  Scenario: License activates a process with a pre-determined ID (bad ID)
    Given the current account is "test1"
    And the current account has 1 "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/processes" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "1",
          "attributes": {
            "pid": "1"
          },
          "relationships": {
            "machine": {
              "data": {
                "type": "machines",
                "id": "$machines[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "type mismatch (received string expected UUID string)",
        "source": {
          "pointer": "/data/id"
        }
      }
      """
    And the current account should have 0 "processes"
