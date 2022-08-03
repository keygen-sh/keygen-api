# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe User, type: :model do
  let(:account) { create(:account) }

  describe '#role_attributes=' do
    context 'on role assignment' do
      it 'should set admin role and permissions' do
        admin   = create(:admin, account:)
        actions = admin.permissions.pluck(:action)
        role    = admin.role

        expect(actions).to match_array admin.default_permissions
        expect(role.admin?).to be true
      end

      it 'should set user role and permissions' do
        user    = create(:user, account:)
        actions = user.permissions.pluck(:action)
        role    = user.role

        expect(actions).to match_array user.default_permissions
        expect(role.user?).to be true
      end
    end

    context 'on role change' do
      it 'should reset permissions when upgraded to admin role' do
        user = create(:user, account:, permissions: %w[token.generate user.read])
        user.change_role!(:admin)

        actions = user.permissions.pluck(:action)
        role    = user.role

        expect(actions).to match_array user.default_permissions
        expect(role.admin?).to be true
      end

      it 'should reset user permissions when downgraded to user role' do
        user = create(:admin, account:, permissions: %w[token.generate user.read])
        user.change_role!(:user)

        actions = user.permissions.pluck(:action)
        role    = user.role

        expect(actions).to match_array user.default_permissions
        expect(role.user?).to be true
      end
    end
  end

  describe '#permissions=' do
    context 'on create' do
      it 'should set default permissions' do
        user    = create(:user, account:)
        actions = user.permissions.pluck(:action)

        expect(actions).to match_array User.default_permissions
      end

      it 'should set custom permissions' do
        user    = create(:user, account:, permissions: %w[license.read license.validate])
        actions = user.permissions.pluck(:action)

        expect(actions).to match_array %w[license.read license.validate]
      end
    end

    context 'on update' do
      it 'should update permissions' do
        user = create(:user, account:)
        user.update!(permissions: %w[license.validate])

        actions = user.permissions.pluck(:action)

        expect(actions).to match_array %w[license.validate]
      end
    end

    context 'with id conflict' do
      it 'should not clobber existing permissions' do
        user = create(:user, account:)

        expect { create(:user, id: user.id, account:, permissions: %w[user.read license.validate]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )

        user.reload

        actions = user.permissions.pluck(:action)

        expect(actions).to match_array User.default_permissions
      end
    end

    context 'with invalid permissions' do
      it 'should raise for unsupported permissions' do
        expect { create(:user, account:, permissions: %w[foo.bar]) }.to(
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
