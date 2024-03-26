# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe License, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable
  it_behaves_like :encryptable
  it_behaves_like :dirtyable

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching policy' do
        environment = create(:environment, account:)
        policy      = create(:policy, account:, environment:)
        license     = create(:license, account:, policy:)

        expect(license.environment).to eq policy.environment
      end

      it 'should not raise when environment matches policy' do
        environment = create(:environment, account:)
        policy      = create(:policy, account:, environment:)

        expect { create(:license, account:, environment:, policy:) }.to_not raise_error
      end

      it 'should raise when environment does not match policy' do
        environment = create(:environment, account:)
        policy      = create(:policy, account:, environment: nil)

        expect { create(:license, account:, environment:, policy:) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches owner' do
        environment = create(:environment, account:)
        owner       = create(:user, account:, environment:)

        expect { create(:license, account:, environment:, owner:) }.to_not raise_error
      end

      it 'should raise when environment does not match owner' do
        environment = create(:environment, account:)
        owner       = create(:user, account:, environment: nil)

        expect { create(:license, account:, environment:, owner:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches policy' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)

        expect { license.update!(policy: create(:policy, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match policy' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)

        expect { license.update!(policy: create(:policy, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches owner' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)

        expect { license.update!(owner: create(:user, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match owner' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)

        expect { license.update!(owner: create(:user, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#policy=' do
    context 'on build' do
      it 'should denormalize product from unpersisted policy' do
        product = build(:product, account:)
        policy  = build(:policy, product:, account:)
        license = build(:license, policy:, account:)

        expect(license.product_id).to be_nil
        expect(license.product).to eq product
      end

      it 'should denormalize product from persisted policy' do
        policy  = create(:policy, account:)
        license = build(:license, policy:, account:)

        expect(license.product_id).to eq policy.product_id
      end
    end

    context 'on create' do
      it 'should denormalize product from unpersisted policy' do
        product = build(:product, account:)
        policy  = build(:policy, product:, account:)
        license = create(:license, policy:, account:)

        expect(license.product_id).to eq product.id
        expect(license.product).to eq product
      end

      it 'should denormalize product from persisted policy' do
        policy  = create(:policy, account:)
        license = create(:license, policy:, account:)

        expect(license.product_id).to eq policy.product_id
      end
    end

    context 'on update' do
      it 'should denormalize product from policy' do
        policy  = create(:policy, account:)
        license = create(:license, account:)

        license.update!(policy:)

        expect(license.product_id).to eq policy.product_id
      end
    end
  end

  describe '#owner=' do
    context 'on update' do
      it "should not raise when owner is a new user" do
        license = create(:license, :with_owner, account:)
        owner   = create(:user, account:)

        expect { license.update!(owner:) }.to_not raise_error
      end

      it "should raise when owner is an existing user" do
        license = create(:license, :with_licensees, account:)
        owner   = license.licensees.take

        expect { license.update!(owner:) }.to raise_error ActiveRecord::RecordInvalid
      end

      it "should not raise when owner is nil" do
        license = create(:license, :with_owner, account:)

        expect { license.update!(owner: nil) }.to_not raise_error
      end
    end
  end

  describe '#policy=' do
    context 'on build' do
      it 'should denormalize product from policy' do
        policy  = create(:policy, account:)
        license = build(:license, policy:, account:)

        expect(license.product_id).to eq policy.product_id
      end
    end

    context 'on create' do
      it 'should denormalize product from policy' do
        policy  = create(:policy, account:)
        license = create(:license, policy:, account:)

        expect(license.product_id).to eq policy.product_id
      end
    end

    context 'on update' do
      it 'should denormalize product from policy' do
        policy  = create(:policy, account:)
        license = create(:license, account:)

        license.update!(policy:)

        expect(license.product_id).to eq policy.product_id
      end
    end
  end

  describe '#role_attributes=' do
    it 'should set role and permissions' do
      license = create(:license, account:)
      actions = license.permissions.actions
      role    = license.role

      expect(actions).to match_array license.default_permissions
      expect(role.license?).to be true
    end
  end

  describe '#permissions=' do
    context 'on create' do
      it 'should set default permissions' do
        license = create(:license, account:)
        actions = license.permissions.actions

        expect(actions).to match_array License.default_permissions
      end

      it 'should set custom permissions' do
        license = create(:license, account:, permissions: %w[license.read license.validate])
        actions = license.permissions.actions

        expect(actions).to match_array %w[license.read license.validate]
      end

      context 'with wildcard owner permissions' do
        let(:owner) { create(:user, account:, permissions: %w[*]) }

        it 'should set custom permissions' do
          license = create(:license, account:, owner:, permissions: %w[license.read license.validate])
          actions = license.permissions.actions

          expect(actions).to match_array %w[license.read license.validate]
        end
      end
    end

    context 'on update' do
      it 'should update permissions' do
        license = create(:license, account:)
        license.update!(permissions: %w[license.validate])

        actions = license.permissions.actions

        expect(actions).to match_array %w[license.validate]
      end
    end

    context 'with id conflict' do
      it 'should not clobber existing permissions' do
        license = create(:license, account:)

        expect { create(:license, id: license.id, account:, permissions: %w[license.validate]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )

        license.reload

        actions = license.permissions.actions

        expect(actions).to match_array License.default_permissions
      end
    end

    context 'with invalid permissions' do
      allowed_permissions    = Permission::LICENSE_PERMISSIONS
      disallowed_permissions = Permission::ALL_PERMISSIONS - allowed_permissions

      disallowed_permissions.each do |permission|
        it "should raise for #{permission} permission" do
          expect { create(:license, account:, permissions: [permission]) }.to(
            raise_error ActiveRecord::RecordInvalid
          )
        end
      end

      it 'should raise for unsupported permissions' do
        expect { create(:license, account:, permissions: %w[foo.bar]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )
      end
    end
  end

  describe '#permissions' do
    context 'without an owner' do
      it 'should return permissions' do
        license = create(:license, account:)

        expect(license.permissions.ids).to match_array License.default_permission_ids
      end
    end

    context 'with an owner' do
      it 'should return permission intersection' do
        owner   = create(:user, account:, permissions: %w[license.validate license.read machine.read machine.create machine.delete])
        license = create(:license, account:, owner:)
        actions = license.permissions.actions

        expect(actions).to match_array %w[license.validate license.read machine.read machine.create machine.delete]
      end
    end
  end

  describe '.with_status' do
    before do
      # new license (active)
      create(:license, account:)

      # old license (inactive)
      create(:license, account:, created_at: 1.year.ago)

      # old license recently validated (active)
      create(:license, account:, created_at: 1.year.ago, last_validated_at: 1.second.ago)

      # old license expired (inactive, expired)
      create(:license, account:, created_at: 1.year.ago, expiry: 11.months.ago)

      # old license expired recently validated (active, expired)
      create(:license, account:, created_at: 1.year.ago, expiry: 6.months.ago, last_validated_at: 3.days.ago)

      # old license recently checked out (active)
      create(:license, account:, created_at: 1.year.ago, last_check_out_at: 1.second.ago)

      # old license recently checked in (active, expiring)
      create(:license, account:, created_at: 1.year.ago, expiry: 2.days.from_now, last_check_in_at: 1.second.ago)

      # old license expiring (inactive, expiring)
      create(:license, account:, created_at: 1.year.ago, expiry: 2.days.from_now)

      # new license with banned user (active, banned)
      create(:license, :banned, account:)

      # old license recently validated with banned user (active, banned)
      create(:license, :banned, account:, created_at: 1.year.ago, last_validated_at: 1.minute.ago)

      # old license with banned user (inactive, banned)
      create(:license, :banned, account:, created_at: 1.year.ago)
    end

    it 'should return active licenses' do
      expect(License.with_status(:active).count).to eq 5
    end

    it 'should return inactive licenses' do
      expect(License.with_status(:inactive).count).to eq 3
    end

    it 'should return expiring licenses' do
      expect(License.with_status(:expiring).count).to eq 2
    end

    it 'should return expired licenses' do
      expect(License.with_status(:expired).count).to eq 2
    end

    it 'should return banned licenses' do
      expect(License.with_status(:banned).count).to eq 3
    end
  end
end
