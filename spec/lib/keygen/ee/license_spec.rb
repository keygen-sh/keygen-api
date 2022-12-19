# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::License, type: :ee do
  public_key   = ['775e65407f3d86de55efbac47d1bbeab79768a21a406e39976606a704984e7d1'].pack('H*')
  license_key  = 'TEST-116A58-3F79F9-9F1982-9D63B1-V3'
  license_file = Base64.strict_encode64(
    file_fixture('valid.lic').read,
  )

  before do
    stub_const('Keygen::PUBLIC_KEY', public_key)
  end

  context 'when using a valid license file' do
    with_env KEYGEN_LICENSE_FILE: license_file, KEYGEN_LICENSE_KEY: license_key do
      it 'should be a valid license' do
        license = described_class.current

        expect(license.expired?).to be false
        expect(license.valid?).to be true
      end

      it 'should have entitlement attributes' do
        license = described_class.current

        expect(license.entitlements).to match_array [Symbol, Symbol, Symbol]
      end

      it 'should have product attributes' do
        license = described_class.current

        expect(license.product).to be_a String
      end

      it 'should have policy attributes' do
        license = described_class.current

        expect(license.policy).to be_a String
      end

      it 'should have license attributes' do
        license = described_class.current

        expect(license.expiry).to be nil
        expect(license.name).to be_a String
      end
    end
  end

  context 'when using an expired license file' do
    with_file path: Keygen::EE::LicenseFile::DEFAULT_PATH, fixture: 'expired.lic' do
      with_env KEYGEN_LICENSE_KEY: license_key do
        it 'should be an invalid license' do
          license = described_class.current

          expect(license.expired?).to be true
          expect(license.valid?).to be false
        end

        it 'should not have entitlement attributes' do
          license = described_class.current

          expect(license.entitlements).to match_array []
        end

        it 'should not have product attributes' do
          license = described_class.current

          expect(license.product).to be nil
        end

        it 'should not have policy attributes' do
          license = described_class.current

          expect(license.policy).to be nil
        end

        it 'should have license attributes' do
          license = described_class.current

          expect(license.expiry).to be_a Time
          expect(license.name).to be_a String
        end
      end
    end
  end

  context 'when using an invalid license file' do
    with_env KEYGEN_LICENSE_FILE_PATH: '/dev/null', KEYGEN_LICENSE_KEY: license_key do
      it 'should fail to load license' do
        license = described_class.current

        expect { license.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
      end
    end
  end

  context 'when using an invalid license key' do
    with_env KEYGEN_LICENSE_FILE: license_file, KEYGEN_LICENSE_KEY: 'invalid' do
      it 'should fail to load license' do
        license = described_class.current

        expect { license.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
      end
    end
  end
end
