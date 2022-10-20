# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::LicenseFile do
  TEST_PUBLIC_KEY  = ['775e65407f3d86de55efbac47d1bbeab79768a21a406e39976606a704984e7d1'].pack('H*')
  TEST_LICENSE_KEY = 'TEST-116A58-3F79F9-9F1982-9D63B1-V3'

  before do
    stub_const('Keygen::PUBLIC_KEY', TEST_PUBLIC_KEY)
  end

  after do
    described_class.reset!
  end

  context 'when using the default license file source' do
    context 'when a valid license file exists' do
      with_file filename: described_class::DEFAULT_PATH, fixture: 'valid.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
            it 'should be a valid license file' do
              lic = described_class.current

              expect(lic.expired?).to be false
              expect(lic.valid?).to be true
            end
          end
        end

        context 'when an invalid license key is used' do
          with_env KEYGEN_LICENSE_KEY: 'TEST-INVALID' do
            it 'should fail to load license file' do
              lic = described_class.current

              expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
            end
          end
        end
      end
    end

    context 'when an invalid license file exists' do
      with_file filename: described_class::DEFAULT_PATH, fixture: 'expired.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
            it 'should not be a valid license file' do
              lic = described_class.current

              expect(lic.expired?).to be true
              expect(lic.valid?).to be false
            end
          end
        end

        context 'when an invalid license key is used' do
          with_env KEYGEN_LICENSE_KEY: 'TEST-INVALID' do
            it 'should fail to load license file' do
              lic = described_class.current

              expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
            end
          end
        end
      end
    end

    context 'when a license file does not exist' do
      it 'should fail to load license file' do
        lic = described_class.current

        expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
      end
    end
  end
end
