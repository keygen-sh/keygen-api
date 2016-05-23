require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should create account" do
    assert_difference('Account.count') do
      post accounts_url, params: { account: { email: @account.email, name: @account.name, subdomain: @account.subdomain } }
    end

    assert_response 201
  end

  test "should show account" do
    get account_url(@account)
    assert_response :success
  end

  test "should update account" do
    patch account_url(@account), params: { account: { email: @account.email, name: @account.name, subdomain: @account.subdomain } }
    assert_response 200
  end

  test "should destroy account" do
    assert_difference('Account.count', -1) do
      delete account_url(@account)
    end

    assert_response 204
  end
end
