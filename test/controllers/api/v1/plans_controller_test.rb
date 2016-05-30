require 'test_helper'

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = plans(:basic)
  end

  test "should get index" do
    get v1_plans_url
    assert_response :success
  end

  test "should create plan" do
    assert_difference('Plan.count') do
      post v1_plans_url, headers: { "Content-Type": "application/json" },
        params: { plan: { maxLicenses: @plan.max_licenses, maxPolicies: @plan.max_policies, maxUsers: @plan.max_users, name: @plan.name, price: @plan.price } }.to_json
    end

    assert_response 201
  end

  test "should show plan" do
    get v1_plan_url(@plan)
    assert_response :success
  end

  test "should update plan" do
    patch v1_plan_url(@plan), params: { plan: { maxLicenses: @plan.max_licenses, maxPolicies: @plan.max_policies, maxUsers: @plan.max_users, name: @plan.name, price: @plan.price } }
    assert_response 200
  end

  test "should destroy plan" do
    assert_difference('Plan.count', -1) do
      delete v1_plan_url(@plan)
    end

    assert_response 204
  end
end
