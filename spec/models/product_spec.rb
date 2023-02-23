# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Product, type: :model do
  let(:account) { create(:account) }

  describe '#environment=' do
    context 'on create' do
      it 'should not raise when environment exists' do
        environment = create(:environment, account:)

        expect { create(:product, account:, environment:) }.to_not raise_error
      end

      it 'should raise when environment does not exist' do
        expect { create(:product, account:, environment_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment is nil' do
        expect { create(:product, account:, environment: nil) }.to_not raise_error
      end

      it 'should set provided environment' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)

        expect(product.environment).to eq environment
      end

      it 'should set nil environment' do
        product = create(:product, account:, environment: nil)

        expect(product.environment).to be_nil
      end

      context 'with current environment' do
        before { Current.environment = create(:environment, account:) }
        after  { Current.environment = nil }

        it 'should set provided environment' do
          environment = create(:environment, account:)
          product     = create(:product, account:, environment:)

          expect(product.environment).to eq environment
        end

        it 'should default to current environment' do
          product = create(:product, account:)

          expect(product.environment).to eq Current.environment
        end

        it 'should set nil environment' do
          product = create(:product, account:, environment: nil)

          expect(product.environment).to be_nil
        end
      end
    end

    context 'on update' do
      it 'should raise when environment exists' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)

        expect { product.update!(environment: create(:environment, account:)) }.to raise_error ActiveRecord::RecordInvalid
        expect { product.update!(environment: nil) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when environment does not exist' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)

        expect { product.update!(environment_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when environment is nil' do
        product = create(:product, account:, environment: nil)

        expect { product.update!(environment: create(:environment, account:)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

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
