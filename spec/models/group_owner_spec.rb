# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe GroupOwner, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=', only: :ee do
    context 'on create' do
      it 'should apply default environment matching group' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment:)
        owner       = create(:owner, account:, group:, user:)

        expect(owner.environment).to eq group.environment
      end

      it 'should not raise when environment matches group' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment:)

        expect { create(:owner, account:, environment:, group:, user:) }.to_not raise_error
      end

      it 'should raise when environment does not match group' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment: nil)
        user        = create(:user, account:, environment:)

        expect { create(:owner, account:, environment:, group:, user:) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches user' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment:)

        expect { create(:owner, account:, environment:, group:, user:) }.to_not raise_error
      end

      it 'should raise when environment does not match user' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment: nil)

        expect { create(:owner, account:, environment:, group:, user:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches group' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment:)
        owner       = create(:owner, account:, environment:, group:, user:)

        expect { owner.update!(group: create(:group, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match group' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment:)
        owner       = create(:owner, account:, environment:, group:, user:)

        expect { owner.update!(group: create(:group, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches user' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment:)
        owner       = create(:owner, account:, environment:, group:, user:)

        expect { owner.update!(user: create(:user, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match user' do
        environment = create(:environment, account:)
        group       = create(:group, account:, environment:)
        user        = create(:user, account:, environment:)
        owner       = create(:owner, account:, environment:, group:, user:)

        expect { owner.update!(user: create(:user, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
