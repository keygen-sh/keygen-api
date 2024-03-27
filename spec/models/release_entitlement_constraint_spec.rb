# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleaseEntitlementConstraint, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching release' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment:)
        constraint  = create(:constraint, account:, entitlement:, release:)

        expect(constraint.environment).to eq release.environment
      end

      it 'should not raise when environment matches entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment:)

        expect { create(:constraint, account:, environment:, entitlement:, release:) }.to_not raise_error
      end

      it 'should raise when environment does not match entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment: nil)
        release     = create(:release, account:, environment:)

        expect { create(:constraint, account:, environment:, entitlement:, release:) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches release' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment:)

        expect { create(:constraint, account:, environment:, entitlement:, release:) }.to_not raise_error
      end

      it 'should raise when environment does not match release' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment: nil)

        expect { create(:constraint, account:, environment:, entitlement:, release:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment:)
        constraint  = create(:constraint, account:, environment:, entitlement:, release:)

        expect { constraint.update!(entitlement: create(:entitlement, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment:)
        constraint  = create(:constraint, account:, environment:, entitlement:, release:)

        expect { constraint.update!(entitlement: create(:entitlement, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches release' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment:)
        constraint  = create(:constraint, account:, environment:, entitlement:, release:)

        expect { constraint.update!(release: create(:release, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match release' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        release     = create(:release, account:, environment:)
        constraint  = create(:constraint, account:, environment:, entitlement:, release:)

        expect { constraint.update!(release: create(:release, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
