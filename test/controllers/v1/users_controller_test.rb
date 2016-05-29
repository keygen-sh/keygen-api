require 'test_helper'

class V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get index" do
    get v1_users_url
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post v1_users_url, params: { user: { email: @user.email, name: @user.name, password: 'secret', password_confirmation: 'secret', role: @user.role } }
    end

    assert_response 201
  end

  test "should show user" do
    get v1_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch v1_user_url(@user), params: { user: { email: @user.email, name: @user.name, password: 'secret', password_confirmation: 'secret', role: @user.role } }
    assert_response 200
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete v1_user_url(@user)
    end

    assert_response 204
  end
end
