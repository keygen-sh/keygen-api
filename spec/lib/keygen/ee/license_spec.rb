# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::License do
  TEST_PUBLIC_KEY   = ['775e65407f3d86de55efbac47d1bbeab79768a21a406e39976606a704984e7d1'].pack('H*')
  TEST_LICENSE_KEY  = 'TEST-116A58-3F79F9-9F1982-9D63B1-V3'
  TEST_LICENSE_FILE = Base64.strict_encode64(
    file_fixture('valid.lic').read,
  )

  before do
    stub_const('Keygen::PUBLIC_KEY', TEST_PUBLIC_KEY)
  end

  after do
    described_class.reset!
  end

  context 'when using a valid license file' do
    with_env KEYGEN_LICENSE_FILE: TEST_LICENSE_FILE, KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
      it 'should be a valid license' do
        license = described_class.current

        expect(license.expired?).to be false
        expect(license.valid?).to be true
      end
    end
  end

  context 'when using an expired license file' do
    with_file path: Keygen::EE::LicenseFile::DEFAULT_PATH, fixture: 'expired.lic' do
      with_env KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
        it 'should be an invalid license' do
          license = described_class.current

          expect(license.expired?).to be true
          expect(license.valid?).to be false
        end
      end
    end
  end

  context 'when using an invalid license file' do
    with_env KEYGEN_LICENSE_FILE_PATH: '/dev/null', KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
      it 'should fail to load license' do
        license = described_class.current

        expect { license.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
      end
    end
  end

  context 'when using an invalid license key' do
    with_env KEYGEN_LICENSE_FILE: TEST_LICENSE_FILE, KEYGEN_LICENSE_KEY: 'invalid' do
      it 'should fail to load license' do
        license = described_class.current

        expect { license.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
      end
    end
  end
end
