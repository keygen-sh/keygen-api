# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::LicenseFile, type: :ee do
  public_key   = ['775e65407f3d86de55efbac47d1bbeab79768a21a406e39976606a704984e7d1'].pack('H*')
  license_key  = 'TEST-116A58-3F79F9-9F1982-9D63B1-V3'
  license_file = Base64.strict_encode64(
    file_fixture('valid.lic').read,
  )

  before do
    stub_const('Keygen::PUBLIC_KEY', public_key)
  end

  context 'when using the default license file source' do
    context 'when a valid license file exists' do
      with_file path: described_class::DEFAULT_PATH, fixture: 'valid.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: license_key do
            it 'should be a valid license file' do
              lic = described_class.current

              expect(lic.expired?).to be false
              expect(lic.valid?).to be true
            end

            it 'should have entitlement attributes' do
              lic = described_class.current

              expect(lic.entitlements).to match_array [Hash, Hash, Hash]
            end

            it 'should have product attributes' do
              lic = described_class.current

              expect(lic.product).to be_a Hash
            end

            it 'should have policy attributes' do
              lic = described_class.current

              expect(lic.policy).to be_a Hash
            end

            it 'should have license attributes' do
              lic = described_class.current

              expect(lic.license).to be_a Hash
            end

            it 'should raise if clock is desynchronized' do
              lic = described_class.current

              with_time lic.issued - 1.minute do
                expect(lic.desync?).to be true
                expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
              end
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
      with_file path: described_class::DEFAULT_PATH, fixture: 'expired.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: license_key do
            it 'should be an expired license file' do
              lic = described_class.current

              expect(lic.expired?).to be true
            end

            it 'should be invalid within grace period' do
              lic = described_class.current

              with_time lic.expiry + 3.days do
                expect { lic.valid? }.to_not raise_error
                expect(lic.valid?).to be false
              end
            end

            it 'should raise outside grace period' do
              lic = described_class.current

              with_time lic.expiry + 2.months do
                expect { lic.valid? }.to raise_error Keygen::EE::ExpiredLicenseFileError
              end
            end

            it 'should raise with desynchronized clock' do
              lic = described_class.current

              with_time lic.expiry - 3.days do
                expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
              end
            end

            it 'should not have entitlement attributes' do
              lic = described_class.current

              expect(lic.entitlements).to match_array []
            end

            it 'should not have product attributes' do
              lic = described_class.current

              expect(lic.product).to be_nil
            end

            it 'should not have policy attributes' do
              lic = described_class.current

              expect(lic.policy).to be_nil
            end

            it 'should have license attributes' do
              lic = described_class.current

              expect(lic.license).to be_a Hash
            end
          end
        end
      end
    end

    context 'when a tampered license file exists' do
      with_file path: described_class::DEFAULT_PATH, fixture: 'tampered.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: license_key do
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

  context 'when using a custom license file path' do
    context 'when using a real relative path' do
      with_env KEYGEN_LICENSE_FILE_PATH: file_fixture('valid.lic').relative_path_from(Rails.root), KEYGEN_LICENSE_KEY: license_key do
        it 'should be a valid license file' do
          lic = described_class.current

          expect(lic.valid?).to be true
        end
      end
    end

    context 'when using a relative path' do
      with_file path: '.ee.lic', fixture: 'valid.lic' do
        with_env KEYGEN_LICENSE_FILE_PATH: '.ee.lic', KEYGEN_LICENSE_KEY: license_key do
          it 'should be a valid license file' do
            lic = described_class.current

            expect(lic.valid?).to be true
          end
        end
      end
    end

    context 'when using an absolute path' do
      with_file path: '/etc/licenses/ee.lic', fixture: 'valid.lic' do
        with_env KEYGEN_LICENSE_FILE_PATH: '/etc/licenses/ee.lic', KEYGEN_LICENSE_KEY: license_key do
          it 'should be a valid license file' do
            lic = described_class.current

            expect(lic.valid?).to be true
          end
        end
      end
    end

    context 'when using an invalid path' do
      with_env KEYGEN_LICENSE_FILE_PATH: '/dev/null', KEYGEN_LICENSE_KEY: license_key do
        it 'should fail to load license file' do
          lic = described_class.current

          expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
        end
      end
    end
  end

  context 'when using an encoded license file' do
    with_env KEYGEN_LICENSE_FILE: license_file, KEYGEN_LICENSE_KEY: license_key do
      it 'should be a valid license file' do
        lic = described_class.current

        expect(lic.valid?).to be true
      end
    end
  end
end
