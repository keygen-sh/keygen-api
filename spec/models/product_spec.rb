# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Product, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental

  describe '#role_attributes=' do
    it 'should set role and permissions' do
      product = create(:product, account:)
      actions = product.permissions.actions
      role    = product.role

      expect(actions).to match_array product.default_permissions
      expect(role.product?).to be true
    end
  end

  describe '#permissions=' do
    context 'on create' do
      it 'should set default permissions' do
        product = create(:product, account:)
        actions = product.permissions.actions

        expect(actions).to match_array Product.default_permissions
      end

      it 'should set custom permissions' do
        product = create(:product, account:, permissions: %w[product.read])
        actions = product.permissions.actions

        expect(actions).to match_array %w[product.read]
      end
    end

    context 'on update' do
      it 'should update permissions' do
        product = create(:product, account:)
        product.update!(permissions: %w[license.validate])

        actions = product.permissions.actions

        expect(actions).to match_array %w[license.validate]
      end
    end

    context 'with invalid permissions' do
      allowed_permissions    = Permission::PRODUCT_PERMISSIONS
      disallowed_permissions = Permission::ALL_PERMISSIONS - allowed_permissions

      disallowed_permissions.each do |permission|
        it "should raise for #{permission} permission" do
          expect { create(:product, account:, permissions: [permission]) }.to(
            raise_error ActiveRecord::RecordInvalid
          )
        end
      end

      it 'should raise for unsupported permissions' do
        expect { create(:product, account:, permissions: %w[foo.bar]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )
      end
    end
  end

  describe '#permissions' do
    it 'should return permissions' do
      product = create(:product, account:)

      expect(product.permissions.ids).to match_array Product.default_permission_ids
    end
  end
end
