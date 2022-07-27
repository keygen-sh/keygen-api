# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProductPolicy, type: :policy do
  subject { described_class.new(context, resource) }

  with_role_authorization :admin do
    let(:account)  { create(:account) }
    let(:bearer)   { create(:admin, account:, permissions:) }
    let(:resource) { create(:product, account:) }

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
      let(:account)  { create(:account) }
      let(:bearer)   { create(:product, account:, permissions:) }
      let(:resource) { bearer }

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        permits :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        permits :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'as another product' do
      let(:account)  { create(:account) }
      let(:bearer)   { create(:product, account:, permissions:) }
      let(:resource) { create(:product, account:) }

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
      let(:account)  { create(:account) }
      let(:bearer)   { create(:license, account:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }

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
      let(:account)  { create(:account) }
      let(:bearer)   { create(:license, account:, permissions:) }
      let(:resource) { create(:product, account:) }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }

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
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
      let(:licenses) { [create(:license, account:, policy:)] }

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'with license for another product' do
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { create(:product, account:) }
      let(:licenses) { [create(:license, account:)] }

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'with licenses for multiple products' do
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
      let(:licenses) {
        [
          create(:license, account:, policy:),
          create(:license, account:),
          create(:license, account:),
        ]
      }

      with_token_authentication do
        forbids :index,   assert_permissions: %w[product.read]
        forbids :show,    assert_permissions: %w[product.read]
        forbids :create,  assert_permissions: %w[product.create]
        forbids :update,  assert_permissions: %w[product.update]
        forbids :destroy, assert_permissions: %w[product.delete]
      end
    end

    context 'with no licenses' do
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, permissions:) }
      let(:resource) { create(:product, account:) }

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
    let(:account)  { create(:account) }
    let(:resource) { create(:product, account:) }

    without_authentication do
      forbids :index,   assert_permissions: %w[product.read]
      forbids :show,    assert_permissions: %w[product.read]
      forbids :create,  assert_permissions: %w[product.create]
      forbids :update,  assert_permissions: %w[product.update]
      forbids :destroy, assert_permissions: %w[product.delete]
    end
  end
end
