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
end
