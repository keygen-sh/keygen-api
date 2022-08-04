# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Token, type: :model do
  let(:account) { create(:account) }
  let(:bearer) { create(:license, account:) }

  describe '#permissions=' do
    context 'on create' do
      it 'should set wildcard permissions' do
        token   = create(:token, account:, bearer:)
        actions = token.permissions.pluck(:action)
        perms   = token.token_permissions

        expect(actions).to match_array bearer.default_permissions
        expect(perms.count).to eq 1
        expect(perms.map { _1.permission.action }).to match_array %w[*]
      end

      it 'should set custom permissions' do
        token   = create(:token, account:, bearer:, permissions: %w[license.read license.validate])
        actions = token.permissions.pluck(:action)

        expect(actions).to match_array %w[license.read license.validate]
      end
    end

    context 'on update' do
      it 'should update permissions' do
        token = create(:token, account:, bearer:)
        token.update!(permissions: %w[license.validate])

        actions = token.permissions.pluck(:action)

        expect(actions).to match_array %w[license.validate]
      end
    end

    context 'with invalid permissions' do
      it 'should raise for unsupported permissions' do
        expect { create(:token, account:, bearer:, permissions: %w[foo.bar]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )
      end

      it 'should raise for invalid permissions' do
        bearer = create(:user, account:)

        expect { create(:token, account:, bearer:, permissions: %w[product.create]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )
      end

      it 'should raise for exceeded permissions' do
        bearer = create(:user, account:, permissions: %w[license.validate])

        expect { create(:token, account:, bearer:, permissions: %w[license.create]) }.to(
          raise_error ActiveRecord::RecordInvalid
        )
      end
    end
  end

  describe '#permissions' do
    it 'should return default permissions' do
      bearer  = create(:user, account:, permissions: %w[license.validate license.read machine.read machine.create machine.delete])
      token   = create(:token, account:, bearer:)
      actions = token.permissions.pluck(:action)

      expect(actions).to match_array %w[license.validate license.read machine.read machine.create machine.delete]
    end

    it 'should return wildcard permissions' do
      bearer  = create(:user, account:, permissions: %w[license.validate license.read machine.read machine.create machine.delete])
      token   = create(:token, account:, bearer:, permissions: %w[*])
      actions = token.permissions.pluck(:action)

      expect(actions).to match_array %w[license.validate license.read machine.read machine.create machine.delete]
    end

    it 'should return intersected permissions' do
      bearer  = create(:user, account:, permissions: %w[license.validate license.read machine.read machine.create machine.delete])
      token   = create(:token, account:, bearer:, permissions: %w[license.validate license.read])
      actions = token.permissions.pluck(:action)

      expect(actions).to match_array %w[license.validate license.read]
    end
  end
end
