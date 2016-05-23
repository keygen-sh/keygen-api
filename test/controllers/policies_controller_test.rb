require 'test_helper'

class PoliciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @policy = policies(:one)
  end

  test "should get index" do
    get policies_url
    assert_response :success
  end

  test "should create policy" do
    assert_difference('Policy.count') do
      post policies_url, params: { policy: { duration: @policy.duration, floating: @policy.floating, name: @policy.name, pool: @policy.pool, price: @policy.price, recurring: @policy.recurring, strict: @policy.strict, use_pool: @policy.use_pool } }
    end

    assert_response 201
  end

  test "should show policy" do
    get policy_url(@policy)
    assert_response :success
  end

  test "should update policy" do
    patch policy_url(@policy), params: { policy: { duration: @policy.duration, floating: @policy.floating, name: @policy.name, pool: @policy.pool, price: @policy.price, recurring: @policy.recurring, strict: @policy.strict, use_pool: @policy.use_pool } }
    assert_response 200
  end

  test "should destroy policy" do
    assert_difference('Policy.count', -1) do
      delete policy_url(@policy)
    end

    assert_response 204
  end
end
