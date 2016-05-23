require 'test_helper'

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = plans(:one)
  end

  test "should get index" do
    get plans_url
    assert_response :success
  end

  test "should create plan" do
    assert_difference('Plan.count') do
      post plans_url, params: { plan: { max_licenses: @plan.max_licenses, max_policies: @plan.max_policies, max_users: @plan.max_users, name: @plan.name, price: @plan.price } }
    end

    assert_response 201
  end

  test "should show plan" do
    get plan_url(@plan)
    assert_response :success
  end

  test "should update plan" do
    patch plan_url(@plan), params: { plan: { max_licenses: @plan.max_licenses, max_policies: @plan.max_policies, max_users: @plan.max_users, name: @plan.name, price: @plan.price } }
    assert_response 200
  end

  test "should destroy plan" do
    assert_difference('Plan.count', -1) do
      delete plan_url(@plan)
    end

    assert_response 204
  end
end
