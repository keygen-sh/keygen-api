# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PolicyEntitlement, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=', only: :ee do
    context 'on create' do
      it 'should apply default environment matching policy' do
        environment        = create(:environment, account:)
        entitlement        = create(:entitlement, account:, environment:)
        policy             = create(:policy, account:, environment:)
        policy_entitlement = create(:policy_entitlement, account:, entitlement:, policy:)

        expect(policy_entitlement.environment).to eq policy.environment
      end

      it 'should not raise when environment matches entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        policy      = create(:policy, account:, environment:)

        expect { create(:policy_entitlement, account:, environment:, entitlement:, policy:) }.to_not raise_error
      end

      it 'should raise when environment does not match entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment: nil)
        policy      = create(:policy, account:, environment:)

        expect { create(:policy_entitlement, account:, environment:, entitlement:, policy:) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches policy' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        policy      = create(:policy, account:, environment:)

        expect { create(:policy_entitlement, account:, environment:, entitlement:, policy:) }.to_not raise_error
      end

      it 'should raise when environment does not match policy' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        policy      = create(:policy, account:, environment: nil)

        expect { create(:policy_entitlement, account:, environment:, entitlement:, policy:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches entitlement' do
        environment        = create(:environment, account:)
        entitlement        = create(:entitlement, account:, environment:)
        policy             = create(:policy, account:, environment:)
        policy_entitlement = create(:policy_entitlement, account:, environment:, entitlement:, policy:)

        expect { policy_entitlement.update!(entitlement: create(:entitlement, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match entitlement' do
        environment        = create(:environment, account:)
        entitlement        = create(:entitlement, account:, environment:)
        policy             = create(:policy, account:, environment:)
        policy_entitlement = create(:policy_entitlement, account:, environment:, entitlement:, policy:)

        expect { policy_entitlement.update!(entitlement: create(:entitlement, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches policy' do
        environment        = create(:environment, account:)
        entitlement        = create(:entitlement, account:, environment:)
        policy             = create(:policy, account:, environment:)
        policy_entitlement = create(:policy_entitlement, account:, environment:, entitlement:, policy:)

        expect { policy_entitlement.update!(policy: create(:policy, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match policy' do
        environment        = create(:environment, account:)
        entitlement        = create(:entitlement, account:, environment:)
        policy             = create(:policy, account:, environment:)
        policy_entitlement = create(:policy_entitlement, account:, environment:, entitlement:, policy:)

        expect { policy_entitlement.update!(policy: create(:policy, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
