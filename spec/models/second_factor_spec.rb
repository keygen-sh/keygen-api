# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe SecondFactor, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :encryptable

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching user' do
        environment = create(:environment, account:)
        user     = create(:user, account:, environment:)
        second_factor     = create(:second_factor, account:, user:)

        expect(second_factor.environment).to eq user.environment
      end

      it 'should not raise when environment matches user' do
        environment = create(:environment, account:)
        user     = create(:user, account:, environment:)

        expect { create(:second_factor, account:, environment:, user:) }.to_not raise_error
      end

      it 'should raise when environment does not match user' do
        environment = create(:environment, account:)
        user     = create(:user, account:, environment: nil)

        expect { create(:second_factor, account:, environment:, user:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches user' do
        environment = create(:environment, account:)
        second_factor     = create(:second_factor, account:, environment:)

        expect { second_factor.update!(user: create(:user, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match user' do
        environment = create(:environment, account:)
        second_factor     = create(:second_factor, account:, environment:)

        expect { second_factor.update!(user: create(:user, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
