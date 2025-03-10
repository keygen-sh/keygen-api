# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Token, type: :model do
  let(:account) { create(:account) }
  let(:bearer) { create(:license, account:) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=' do
    context 'on create' do
      context 'with user bearer' do
        it 'should apply default environment matching user' do
          environment = create(:environment, account:)
          bearer      = create(:user, account:, environment:)
          token       = create(:token, account:, bearer:)

          expect(token.environment).to eq bearer.environment
        end

        it 'should not raise when environment matches bearer' do
          environment = create(:environment, account:)
          bearer      = create(:user, account:, environment:)

          expect { create(:token, account:, environment:, bearer:) }.to_not raise_error
        end

        it 'should raise when environment does not match bearer' do
          environment = create(:environment, account:)
          bearer      = create(:user, account:, environment: nil)

          expect { create(:token, account:, environment:, bearer:) }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'with product bearer' do
        it 'should apply default environment matching product' do
          environment = create(:environment, account:)
          bearer      = create(:product, account:, environment:)
          token       = create(:token, account:, bearer:)

          expect(token.environment).to eq bearer.environment
        end

        it 'should not raise when environment matches bearer' do
          environment = create(:environment, account:)
          bearer      = create(:product, account:, environment:)

          expect { create(:token, account:, environment:, bearer:) }.to_not raise_error
        end

        it 'should raise when environment does not match bearer' do
          environment = create(:environment, account:)
          bearer      = create(:product, account:, environment: nil)

          expect { create(:token, account:, environment:, bearer:) }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'with license bearer' do
        it 'should apply default environment matching license' do
          environment = create(:environment, account:)
          bearer      = create(:license, account:, environment:)
          token       = create(:token, account:, bearer:)

          expect(token.environment).to eq bearer.environment
        end

        it 'should not raise when environment matches bearer' do
          environment = create(:environment, account:)
          bearer      = create(:license, account:, environment:)

          expect { create(:token, account:, environment:, bearer:) }.to_not raise_error
        end

        it 'should raise when environment does not match bearer' do
          environment = create(:environment, account:)
          bearer      = create(:license, account:, environment: nil)

          expect { create(:token, account:, environment:, bearer:) }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end

    context 'on update' do
      context 'with user bearer' do
        it 'should not raise when environment matches bearer' do
          environment = create(:environment, account:)
          token       = create(:token, account:, environment:)

          expect { token.update!(bearer: create(:user, account:, environment:)) }.to_not raise_error
        end

        it 'should raise when environment does not match bearer' do
          environment = create(:environment, account:)
          token       = create(:token, account:, environment:)

          expect { token.update!(bearer: create(:user, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'with product bearer' do
        it 'should not raise when environment matches bearer' do
          environment = create(:environment, account:)
          token       = create(:token, account:, environment:)

          expect { token.update!(bearer: create(:product, account:, environment:)) }.to_not raise_error
        end

        it 'should raise when environment does not match bearer' do
          environment = create(:environment, account:)
          token       = create(:token, account:, environment:)

          expect { token.update!(bearer: create(:product, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'with license bearer' do
        it 'should not raise when environment matches bearer' do
          environment = create(:environment, account:)
          token       = create(:token, account:, environment:)

          expect { token.update!(bearer: create(:license, account:, environment:)) }.to_not raise_error
        end

        it 'should raise when environment does not match bearer' do
          environment = create(:environment, account:)
          token       = create(:token, account:, environment:)

          expect { token.update!(bearer: create(:license, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end
  end

  describe '#permissions=' do
    context 'on create' do
      it 'should set wildcard permissions' do
        token = create(:token, account:, bearer:)

        expect(token.permissions.actions).to match_array bearer.default_permissions
        expect(token.token_permissions.count).to eq 1
        expect(token.token_permissions.actions).to match_array %w[*]
      end

      it 'should set custom permissions' do
        token   = create(:token, account:, bearer:, permissions: %w[license.read license.validate])
        actions = token.permissions.actions

        expect(actions).to match_array %w[license.read license.validate]
      end

      context 'with wildcard bearer permissions' do
        let(:bearer) { create(:license, account:, permissions: %w[*]) }

        it 'should set custom permissions' do
          token   = create(:token, account:, bearer:, permissions: %w[license.read license.validate])
          actions = token.permissions.actions

          expect(actions).to match_array %w[license.read license.validate]
        end
      end
    end

    context 'on update' do
      it 'should update permissions' do
        token = create(:token, account:, bearer:)
        token.update!(permissions: %w[license.validate])

        actions = token.permissions.actions

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
      actions = token.permissions.actions

      expect(actions).to match_array %w[license.validate license.read machine.read machine.create machine.delete]
    end

    it 'should return wildcard permissions' do
      bearer  = create(:user, account:, permissions: %w[license.validate license.read machine.read machine.create machine.delete])
      token   = create(:token, account:, bearer:, permissions: %w[*])
      actions = token.permissions.actions

      expect(actions).to match_array %w[license.validate license.read machine.read machine.create machine.delete]
    end

    it 'should return intersected permissions' do
      bearer  = create(:user, account:, permissions: %w[license.validate license.read machine.read machine.create machine.delete])
      token   = create(:token, account:, bearer:, permissions: %w[license.validate license.read])
      actions = token.permissions.actions

      expect(actions).to match_array %w[license.validate license.read]
    end
  end

  describe '#generate!' do
    let(:bearer) { create(:user, account:) }
    let(:token)  { create(:token, bearer:, account:) }

    it 'should generate an implicit v3 token' do
      token.generate!

      expect(token.persisted?).to be true
      expect(token.digest).to_not eq token.raw
      expect(token.digest.size).to eq 64

      expect(token.raw).to start_with 'user-'
      expect(token.raw).to end_with 'v3'
      expect(token.raw.size).to eq 5 + 64 + 2
    end

    it 'should generate an explicit v3 token' do
      token.generate!(version: 'v3')

      expect(token.raw).to start_with 'user-'
      expect(token.raw).to end_with 'v3'
      expect(token.raw.size).to eq 5 + 64 + 2
    end

    it 'should generate an explicit v2 token' do
      token.generate!(version: 'v2')

      expect(token.raw).to start_with 'user-'
      expect(token.raw).to end_with 'v2'
      expect(token.raw.size).to eq 5 + 64
    end

    it 'should generate an explicit v1 token' do
      token.generate!(version: 'v1')

      expect(token.raw).to start_with token.account_id.delete('-') + '.'
      expect(token.raw).to end_with 'v1'
      expect(token.raw.size).to eq 32 + 1 + 32 + 1 + 64
    end
  end

  describe '#regenerate!' do
    let(:token) { create(:token, account:) }

    it 'should call #generate!' do
      expect(token).to receive(:generate!).with(version: 'v3')

      token.regenerate!(version: 'v3')
    end

    it 'should regenerate token' do
      digest_was = token.digest
      raw_was    = token.raw

      token.regenerate!

      expect(token.digest).to_not eq digest_was
      expect(token.digest.size).to eq 64

      expect(token.raw).to_not eq raw_was
      expect(token.raw).to start_with 'user-'
      expect(token.raw).to end_with 'v3'
      expect(token.raw.size).to eq 5 + 64 + 2
    end

    it 'should clear sessions' do
      token.sessions = create_list(:session, 3, token:)

      expect(token.sessions).to_not be_empty

      token.regenerate!

      expect(token.sessions).to be_empty
    end

    it 'should regenerate session' do
      old_session = create(:session, token:)
      new_session = token.regenerate!(
        session: old_session,
      )

      expect(new_session).to_not eq old_session
      expect(token.sessions).to_not include old_session
      expect(token.sessions).to include new_session
    end

    it 'should not regenerate session' do
      other_session = create(:session, account:)
      new_session   = token.regenerate!(
        session: other_session,
      )

      expect(new_session).to be_nil
      expect(token.sessions).to be_empty
    end
  end
end
