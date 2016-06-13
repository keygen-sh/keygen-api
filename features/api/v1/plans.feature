Feature: /v1/plans

  Scenario: List plans in JSON
    When I send and accept JSON
    And I send a GET request to "/v1/plans"
    Then the response status should be "200"
    And the JSON response should be:
      """
      {"data":[{"id":"ElZw7Zko","type":"plans","attributes":{"name":"Weekender","price":0,"maxProducts":1,"maxUsers":250,"maxPolicies":1,"maxLicenses":250}},{"id":"D7Z6xzrW","type":"plans","attributes":{"name":"Startup","price":2400,"maxProducts":5,"maxUsers":1000,"maxPolicies":5,"maxLicenses":5000}},{"id":"l2zk2GjY","type":"plans","attributes":{"name":"Business","price":4900,"maxProducts":25,"maxUsers":5000,"maxPolicies":25,"maxLicenses":25000}}]}
      """
