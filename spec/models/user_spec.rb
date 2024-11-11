# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe User, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

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

  context 'with a variety of users' do
    before do
      # new user (active)
      create(:user, account:)

      # old user (inactive)
      create(:user, account:, created_at: 1.year.ago)

      # old user with new owned license (active)
      owner = create(:user, account:, created_at: 1.year.ago)

      create(:license, account:, owner:, created_at: 1.week.ago, last_validated_at: 1.second.ago)

      # old user with new user license (active)
      user    = create(:user, account:, created_at: 1.year.ago)
      license = create(:license, account:, created_at: 1.week.ago, last_validated_at: 1.second.ago)

      create(:license_user, account:, license:, user:)

      # old user with old owned license (inactive)
      owner = create(:user, account:, created_at: 1.year.ago)

      create(:license, account:, owner:, created_at: 1.year.ago)

      # old user with old user license (inactive)
      user    = create(:user, account:, created_at: 1.year.ago)
      license = create(:license, account:, created_at: 1.year.ago)

      create(:license_user, account:, license:, user:)

      # old user with recently validated owned license (active)
      owner = create(:user, account:, created_at: 1.year.ago)

      create(:license, account:, owner:, last_validated_at: 1.year.ago, last_check_out_at: 32.days.ago)

      # old user with recently validated user license (active)
      user    = create(:user, account:, created_at: 1.year.ago)
      license = create(:license, account:, last_validated_at: 1.year.ago, last_check_out_at: 32.days.ago)

      create(:license_user, account:, license:, user:)

      # old user with recently checked out owned license (active)
      owner = create(:user, account:, created_at: 1.year.ago)

      create(:license, account:, owner:, last_validated_at: 32.days.ago, last_check_out_at: 1.day.ago)

      # old user with recently checked out user license (active)
      user    = create(:user, account:, created_at: 1.year.ago)
      license = create(:license, account:, last_validated_at: 32.days.ago, last_check_out_at: 1.day.ago)

      create(:license_user, account:, license:, user:)

      # old user with recently checked in owned license (active)
      owner = create(:user, account:, created_at: 1.year.ago)

      create(:license, account:, owner:, last_check_in_at: 6.days.ago)

      # old user with recently checked in user license (active)
      user    = create(:user, account:, created_at: 1.year.ago)
      license = create(:license, account:, last_check_in_at: 6.days.ago)

      create(:license_user, account:, license:, user:)

      # old user with active and inactive owned licenses (active)
      owner = create(:user, account:, created_at: 1.year.ago)

      create(:license, account:, owner:, created_at: 2.years.ago, last_validated_at: 1.year.ago)
      create(:license, account:, owner:, last_check_in_at: 6.days.ago)

      # old user with active and inactive user licenses (active)
      user = create(:user, account:, created_at: 1.year.ago)

      license = create(:license, account:, created_at: 2.years.ago, last_validated_at: 1.year.ago)
      create(:license_user, account:, license:, user:)

      license = create(:license, account:, last_check_in_at: 6.days.ago)
      create(:license_user, account:, license:, user:)

      # banned user (banned)
      create(:user, :banned, account:)
    end

    it 'should preload user statuses' do
      statuses = nil
      expect { statuses = User.preload(:any_active_licenses).collect(&:status) }.to match_queries(count: 4)
      expect(statuses).to eq User.all.collect(&:status)
    end

    it 'should return active users' do
      expect(User.users.with_status(:active).count).to eq 11
    end

    it 'should return inactive users' do
      expect(User.users.with_status(:inactive).count).to eq 3
    end

    it 'should return banned users' do
      expect(User.users.with_status(:banned).count).to eq 1
    end
  end

  describe '#destroy' do
    before { Sidekiq::Testing.inline! }
    after  { Sidekiq::Testing.fake! }

    it 'should destroy owned machines' do
      user    = create(:user, account:)
      license = create(:license, account:)

      create(:license_user, account:, license:, user:)
      create(:machine, account:, license:, owner: user)
      create(:machine, account:, license:)

      perform_enqueued_jobs only: ActiveRecord::DestroyAssociationAsyncJob do
        expect { user.destroy }.to change { license.machines.count }.by -1
      end
    end
  end
end
