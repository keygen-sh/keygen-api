require 'test_helper'

class PoliciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @policy = policies(:one)
  end

  test "should get index" do
    get v1_policies_url
    assert_response :success
  end

  test "should create policy" do
    assert_difference('Policy.count') do
      post v1_policies_url, headers: { "Content-Type": "application/json" },
        params: { policy: { duration: @policy.duration, floating: @policy.floating, name: @policy.name, pool: @policy.pool, price: @policy.price, recurring: @policy.recurring, strict: @policy.strict, usePool: @policy.use_pool, account: @policy.account } }.to_json
    end

    assert_response 201
  end

  test "should show policy" do
    get v1_policy_url(@policy)
    assert_response :success
  end

  test "should update policy" do
    patch v1_policy_url(@policy), headers: { "Content-Type": "application/json" },
      params: { policy: { duration: @policy.duration, floating: @policy.floating, name: @policy.name, pool: @policy.pool, price: @policy.price, recurring: @policy.recurring, strict: @policy.strict, usePool: @policy.use_pool } }.to_json
    assert_response 200
  end

  test "should destroy policy" do
    assert_difference('Policy.count', -1) do
      delete v1_policy_url(@policy)
    end

    assert_response 204
  end
end
