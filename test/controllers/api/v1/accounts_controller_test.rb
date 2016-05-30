require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
  end

  test "should get index" do
    get v1_accounts_url
    assert_response :success
  end

  test "should create account" do
    assert_difference('Account.count') do
      post v1_accounts_url, params: { account: { email: @account.email, name: @account.name, subdomain: @account.subdomain, planId: @account.plan } }
    end

    assert_response 201
  end

  test "should show account" do
    get v1_account_url(@account)
    assert_response :success
  end

  test "should update account" do
    patch v1_account_url(@account), params: { account: { email: @account.email, name: @account.name, subdomain: @account.subdomain } }
    assert_response 200
  end

  test "should destroy account" do
    assert_difference('Account.count', -1) do
      delete v1_account_url(@account)
    end

    assert_response 204
  end
end
