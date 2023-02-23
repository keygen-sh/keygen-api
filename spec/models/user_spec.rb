# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe User, type: :model do
  let(:account) { create(:account) }

  describe '#environment=' do
    context 'on create' do
      it 'should not raise when environment exists' do
        environment = create(:environment, account:)

        expect { create(:user, account:, environment:) }.to_not raise_error
      end

      it 'should raise when environment does not exist' do
        expect { create(:user, account:, environment_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment is nil' do
        expect { create(:user, account:, environment: nil) }.to_not raise_error
      end

      it 'should set provided environment' do
        environment = create(:environment, account:)
        user        = create(:user, account:, environment:)

        expect(user.environment).to eq environment
      end

      it 'should set nil environment' do
        user = create(:user, account:, environment: nil)

        expect(user.environment).to be_nil
      end

      context 'with current environment' do
        before { Current.environment = create(:environment, account:) }
        after  { Current.environment = nil }

        it 'should set provided environment' do
          environment = create(:environment, account:)
          user        = create(:user, account:, environment:)

          expect(user.environment).to eq environment
        end

        it 'should default to current environment' do
          user = create(:user, account:)

          expect(user.environment).to eq Current.environment
        end

        it 'should set nil environment' do
          user = create(:user, account:, environment: nil)

          expect(user.environment).to be_nil
        end
      end
    end

    context 'on update' do
      it 'should raise when environment exists' do
        environment = create(:environment, account:)
        user        = create(:user, account:, environment:)

        expect { user.update!(environment: create(:environment, account:)) }.to raise_error ActiveRecord::RecordInvalid
        expect { user.update!(environment: nil) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when environment does not exist' do
        environment = create(:environment, account:)
        user        = create(:user, account:, environment:)

        expect { user.update!(environment_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when environment is nil' do
        user = create(:user, account:, environment: nil)

        expect { user.update!(environment: create(:environment, account:)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#role_attributes=' do
    context 'on role assignment' do
      it 'should set admin role and permissions' do
        admin   = create(:admin, account:)
        actions = admin.permissions.actions
        role    = admin.role

        expect(actions).to match_array Permission::ADMIN_PERMISSIONS
        expect(role.admin?).to be true
      end

      it 'should set user role and permissions' do
        user    = create(:user, account:)
        actions = user.permissions.actions
        role    = user.role

        expect(actions).to match_array User.default_permissions
        expect(role.user?).to be true
      end
    end

    context 'on role change' do
      context 'for standard accounts' do
        let(:account) { create(:account, :std) }

        it 'should reset permissions when upgraded to admin role' do
          user = create(:user, account:)
          user.change_role!(:admin)

          admin   = user.reload
          actions = admin.permissions.actions
          role    = admin.role

          expect(actions).to match_array admin.default_permissions
          expect(role.admin?).to be true
        end

        it 'should reset permissions when downgraded to user role' do
          admin = create(:admin, account:)
          admin.change_role!(:user)

          user    = admin.reload
          actions = user.permissions.actions
          role    = user.role

          expect(actions).to match_array user.default_permissions
          expect(role.user?).to be true
        end
      end

      context 'for ent accounts' do
        let(:account) { create(:account, :ent) }

        it 'should intersect permissions when upgraded to admin role' do
          user = create(:user, account:)
          user.change_role!(:admin)

          admin   = user.reload
          actions = admin.permissions.actions
          role    = admin.role

          expect(actions).to match_array User.default_permissions
          expect(role.admin?).to be true
        end

        it 'should intersect permissions when downgraded to user role' do
          admin = create(:admin, account:)
          admin.change_role!(:user)

          user    = admin.reload
          actions = user.permissions.actions
          role    = user.role

          expect(actions).to match_array User.default_permissions
          expect(role.user?).to be true
        end

        it 'should intersect custom permissions when changing role' do
          user = create(:user, account:, permissions: %w[license.validate license.read])
          user.change_role!(:admin)
          # Oops! Change back!
          user.change_role!(:user)

          actions = user.permissions.actions
          role    = user.role

          expect(actions).to match_array %w[license.validate license.read]
          expect(role.user?).to be true
        end

        it 'should maintain wildcard permissions when changing roles' do
          user = create(:user, account:, permissions: %w[*])

          user.change_role!(:admin)
          admin = user.reload

          expect(admin.permissions.actions).to match_array %w[*]
          expect(admin.admin?).to be true

          admin.change_role!(:user)
          user = admin.reload

          expect(user.permissions.actions).to match_array %w[*]
          expect(user.user?).to be true
        end
      end

      it 'should revoke tokens' do
        user   = create(:admin, account:, permissions: %w[token.generate user.read])
        tokens = create_list(:token, 3, account:, bearer: user)

        user.change_role!(:user)

        expect(user.tokens.count).to eq 0
      end
    end
  end

  describe '#permissions=' do
    context 'on create' do
      it 'should set default permissions' do
        user    = create(:user, account:)
        actions = user.permissions.actions

        expect(actions).to match_array User.default_permissions
      end

      it 'should set custom permissions' do
        user    = create(:user, account:, permissions: %w[license.read license.validate])
        actions = user.permissions.actions

        expect(actions).to match_array %w[license.read license.validate]
      end
    end

    context 'on update' do
      it 'should update permissions' do
        user = create(:user, account:)
        user.update!(permissions: %w[license.validate])

        actions = user.permissions.actions

        expect(actions).to match_array %w[license.validate]
      end

      it 'should not revoke tokens' do
        user   = create(:user, account:, permissions: %w[license.validate])
        tokens = create_list(:token, 3, account:, bearer: user)

        user.update!(permissions: %w[license.validate machine.create])

        expect(user.tokens.count).to eq 3
      end
    end

    context 'with id conflict' do
      it 'should not clobber existing permissions' do
        user = create(:user, account:)

        expect { create(:user, id: user.id, account:, permissions: %w[user.read license.validate]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )

        user.reload

        actions = user.permissions.actions

        expect(actions).to match_array User.default_permissions
      end
    end

    context 'with invalid permissions' do
      allowed_permissions    = Permission::USER_PERMISSIONS
      disallowed_permissions = Permission::ALL_PERMISSIONS - allowed_permissions

      disallowed_permissions.each do |permission|
        it "should raise for #{permission} permission" do
          expect { create(:user, account:, permissions: [permission]) }.to(
            raise_error ActiveRecord::RecordInvalid
          )
        end
      end

      it 'should raise for unsupported permissions' do
        expect { create(:admin, account:, permissions: %w[foo.bar]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )
      end
    end
  end

  describe '#permissions' do
    it 'should return permissions' do
      user = create(:user, account:)

      expect(user.permissions.ids).to match_array User.default_permission_ids
    end
  end
end
