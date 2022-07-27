# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProductPolicy, type: :policy do
  subject { described_class.new(context, resource) }

  with_role_authorization :admin do
    with_scenario :as_admin_accessing_product

    with_token_authentication do
      permits :index,   assert_permissions: %w[product.read]
      permits :show,    assert_permissions: %w[product.read]
      permits :create,  assert_permissions: %w[product.create]
      permits :update,  assert_permissions: %w[product.update]
      permits :destroy, assert_permissions: %w[product.delete]
    end
  end

  with_role_authorization :product do
    context 'as current product' do
      with_scenario :as_product_accessing_itself

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        permits :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        permits :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'as another product' do
      with_scenario :as_product_accessing_another_product

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end
  end

  with_role_authorization :license do
    context 'for current product' do
      with_scenario :as_license_accessing_product

      with_license_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'for another product' do
      with_scenario :as_license_accessing_another_product

      with_license_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end
  end

  with_role_authorization :user do
    context 'with license for current product' do
      with_scenario :as_licensed_user_accessing_product

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'with license for another product' do
      with_scenario :as_licensed_user_accessing_another_product

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'with licenses for multiple products' do
      with_scenario :as_licensed_user_with_multiple_licenses_accessing_product

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'with no licenses' do
      with_scenario :as_unlicensed_user_accessing_product

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end
  end

  without_authorization do
    with_scenario :as_anonymous_accessing_product

    without_authentication do
      forbids :index,   assert_permissions: %w[product.read]
      forbids :show,    assert_permissions: %w[product.read]
      forbids :create,  assert_permissions: %w[product.create]
      forbids :update,  assert_permissions: %w[product.update]
      forbids :destroy, assert_permissions: %w[product.delete]
    end
  end
end
