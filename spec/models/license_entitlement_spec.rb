# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseEntitlement, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching license' do
        environment         = create(:environment, account:)
        entitlement         = create(:entitlement, account:, environment:)
        license             = create(:license, account:, environment:)
        license_entitlement = create(:license_entitlement, account:, entitlement:, license:)

        expect(license_entitlement.environment).to eq license.environment
      end

      it 'should not raise when environment matches entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        license     = create(:license, account:, environment:)

        expect { create(:license_entitlement, account:, environment:, entitlement:, license:) }.to_not raise_error
      end

      it 'should raise when environment does not match entitlement' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment: nil)
        license     = create(:license, account:, environment:)

        expect { create(:license_entitlement, account:, environment:, entitlement:, license:) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches license' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        license     = create(:license, account:, environment:)

        expect { create(:license_entitlement, account:, environment:, entitlement:, license:) }.to_not raise_error
      end

      it 'should raise when environment does not match license' do
        environment = create(:environment, account:)
        entitlement = create(:entitlement, account:, environment:)
        license     = create(:license, account:, environment: nil)

        expect { create(:license_entitlement, account:, environment:, entitlement:, license:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches entitlement' do
        environment         = create(:environment, account:)
        entitlement         = create(:entitlement, account:, environment:)
        license             = create(:license, account:, environment:)
        license_entitlement = create(:license_entitlement, account:, environment:, entitlement:, license:)

        expect { license_entitlement.update!(entitlement: create(:entitlement, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match entitlement' do
        environment         = create(:environment, account:)
        entitlement         = create(:entitlement, account:, environment:)
        license             = create(:license, account:, environment:)
        license_entitlement = create(:license_entitlement, account:, environment:, entitlement:, license:)

        expect { license_entitlement.update!(entitlement: create(:entitlement, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches license' do
        environment         = create(:environment, account:)
        entitlement         = create(:entitlement, account:, environment:)
        license             = create(:license, account:, environment:)
        license_entitlement = create(:license_entitlement, account:, environment:, entitlement:, license:)

        expect { license_entitlement.update!(license: create(:license, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match license' do
        environment         = create(:environment, account:)
        entitlement         = create(:entitlement, account:, environment:)
        license             = create(:license, account:, environment:)
        license_entitlement = create(:license_entitlement, account:, environment:, entitlement:, license:)

        expect { license_entitlement.update!(license: create(:license, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
