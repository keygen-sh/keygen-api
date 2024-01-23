# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe License, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
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

      it 'should not raise when environment matches user' do
        environment = create(:environment, account:)
        user        = create(:user, account:, environment:)

        expect { create(:license, account:, environment:, user:) }.to_not raise_error
      end

      it 'should raise when environment does not match user' do
        environment = create(:environment, account:)
        user        = create(:user, account:, environment: nil)

        expect { create(:license, account:, environment:, user:) }.to raise_error ActiveRecord::RecordInvalid
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

      it 'should not raise when environment matches user' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)

        expect { license.update!(user: create(:user, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match user' do
        environment = create(:environment, account:)
        license     = create(:license, account:, environment:)

        expect { license.update!(user: create(:user, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
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

      context 'with wildcard user permissions' do
        let(:user) { create(:user, account:, permissions: %w[*]) }

        it 'should set custom permissions' do
          license = create(:license, account:, user:, permissions: %w[license.read license.validate])
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
    context 'without a user' do
      it 'should return permissions' do
        license = create(:license, account:)

        expect(license.permissions.ids).to match_array License.default_permission_ids
      end
    end

    context 'with a user' do
      it 'should return permission intersection' do
        user    = create(:user, account:, permissions: %w[license.validate license.read machine.read machine.create machine.delete])
        license = create(:license, account:, user:)
        actions = license.permissions.actions

        expect(actions).to match_array %w[license.validate license.read machine.read machine.create machine.delete]
      end
    end
  end
end
