# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Key, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching policy' do
        environment = create(:environment, account:)
        policy      = create(:policy, :pooled, account:, environment:)
        key         = create(:key, account:, policy:)

        expect(key.environment).to eq policy.environment
      end

      it 'should not raise when environment matches policy' do
        environment = create(:environment, account:)
        policy      = create(:policy, :pooled, account:, environment:)

        expect { create(:key, account:, environment:, policy:) }.to_not raise_error
      end

      it 'should raise when environment does not match policy' do
        environment = create(:environment, account:)
        policy      = create(:policy, :pooled, account:, environment: nil)

        expect { create(:key, account:, environment:, policy:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches policy' do
        environment = create(:environment, account:)
        key         = create(:key, account:, environment:)

        expect { key.update!(policy: create(:policy, :pooled, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match policy' do
        environment = create(:environment, account:)
        key         = create(:key, account:, environment:)

        expect { key.update!(policy: create(:policy, :pooled, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
