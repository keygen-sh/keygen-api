# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe MachineCheckoutService do
  let(:account) { create(:account) }
  let(:license) { create(:license, account: account) }
  let(:machine) { create(:machine, license: license, account: account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.fake!
  end

  after do
    DatabaseCleaner.clean
  end

  it 'should return a machine file certificate' do
    machine_file = MachineCheckoutService.call(
      account: account,
      machine: machine,
    )

    cert = machine_file.certificate

    expect(machine_file.account_id).to eq account.id
    expect(machine_file.machine_id).to eq machine.id
    expect(machine_file.license_id).to eq license.id

    expect(cert).to start_with "-----BEGIN MACHINE FILE-----\n"
    expect(cert).to end_with "-----END MACHINE FILE-----\n"
  end

  it 'should return an encoded JSON payload' do
    machine_file = MachineCheckoutService.call(
      account: account,
      machine: machine,
    )

    cert = machine_file.certificate
    dec  = nil
    enc  = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
               .delete_suffix("-----END MACHINE FILE-----\n")

    expect { dec = Base64.decode64(enc) }.to_not raise_error
    expect(dec).to_not be_nil

    json = nil

    expect { json = JSON.parse(dec) }.to_not raise_error
    expect(json).to_not be_nil
    expect(json).to include(
      'enc' => a_kind_of(String),
      'sig' => a_kind_of(String),
      'alg' => a_kind_of(String),
    )
  end

  it 'should return an encoded machine' do
    machine_file = MachineCheckoutService.call(
      account: account,
      machine: machine,
    )

    cert    = machine_file.certificate
    payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                  .delete_suffix("-----END MACHINE FILE-----\n")

    json = JSON.parse(Base64.decode64(payload))
    enc  = json.fetch('enc')
    data = nil

    expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

    expect(data).to_not be_nil
    expect(data).to include(
      'meta' => include(
        'issued' => machine_file.issued_at.iso8601(3),
        'expiry' => machine_file.expires_at.iso8601(3),
        'ttl' => machine_file.ttl,
      ),
      'data' => include(
        'type' => 'machines',
        'id' => machine.id,
      ),
    )
  end

  context 'when invalid parameters are supplied to the service' do
    it 'should raise an error when account is nil' do
      checkout = -> {
        MachineCheckoutService.call(
          account: nil,
          machine: machine,
        )
      }

      expect { checkout.call }.to raise_error MachineCheckoutService::InvalidAccountError
    end

    it 'should raise an error when machine is nil' do
      checkout = -> {
        MachineCheckoutService.call(
          account: account,
          machine: nil,
        )
      }

      expect { checkout.call }.to raise_error MachineCheckoutService::InvalidMachineError
    end

    it 'should raise an error when includes are invalid' do
      checkout = -> {
        MachineCheckoutService.call(
          account: account,
          machine: machine,
          include: %w[
            account
          ]
        )
      }

      expect { checkout.call }.to raise_error MachineCheckoutService::InvalidIncludeError
    end

    it 'should raise an error when TTL is too short' do
      checkout = -> {
        MachineCheckoutService.call(
          account: account,
          machine: machine,
          ttl: 1.minute,
        )
      }

      expect { checkout.call }.to raise_error MachineCheckoutService::InvalidTTLError
    end
  end

  %w[
    ED25519_SIGN
  ].each do |scheme|
    context "when the signing scheme is #{scheme}" do
      let(:policy) { create(:policy, scheme.downcase.to_sym, account: account) }
      let(:license) { create(:license, policy: policy, account: account) }

      context 'when the machine file is not encrypted' do
        it 'should have a correct algorithm' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'base64+ed25519'
          )
        end

        it 'should sign the encoded payload' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
          verify     = -> {
            verify_key.verify(sig_bytes, "machine/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end

      context 'when the machine file is encrypted' do
        it 'should have a correct algorithm' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
            encrypt: true,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'aes-256-gcm+ed25519'
          )
        end

        it 'should sign the encrypted payload' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
            encrypt: true,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
          verify     = -> {
            verify_key.verify(sig_bytes, "machine/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end
    end
  end

  %w[
    RSA_2048_PKCS1_PSS_SIGN_V2
    RSA_2048_PKCS1_PSS_SIGN
  ].each do |scheme|
    context "when the signing scheme is #{scheme}" do
      let(:policy) { create(:policy, scheme.downcase.to_sym, account: account) }
      let(:license) { create(:license, policy: policy, account: account) }

      context 'when the machine file is not encrypted' do
        it 'should have a correct algorithm' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'base64+rsa-pss-sha256'
          )
        end

        it 'should sign the encoded payload' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify_pss(digest, sig_bytes, "machine/#{enc}", salt_length: :auto, mgf1_hash: 'SHA256')
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end

      context 'when the machine file is encrypted' do
        it 'should have a correct algorithm' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
            encrypt: true,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'aes-256-gcm+rsa-pss-sha256'
          )
        end

        it 'should sign the encrypted payload' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
            encrypt: true,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify_pss(digest, sig_bytes, "machine/#{enc}", salt_length: :auto, mgf1_hash: 'SHA256')
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end
    end
  end

  %w[
    RSA_2048_PKCS1_SIGN_V2
    RSA_2048_PKCS1_SIGN
    RSA_2048_PKCS1_ENCRYPT
    RSA_2048_JWT_RS256
  ].each do |scheme|
    context "when the signing scheme is #{scheme}" do
      let(:policy) { create(:policy, scheme.downcase.to_sym, account: account) }
      let(:license) { create(:license, policy: policy, account: account) }

      context 'when the machine file is not encrypted' do
        it 'should have a correct algorithm' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'base64+rsa-sha256'
          )
        end

        it 'should sign the encoded payload' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify(digest, sig_bytes, "machine/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end

      context 'when the machine file is encrypted' do
        it 'should have a correct algorithm' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
            encrypt: true,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'aes-256-gcm+rsa-sha256'
          )
        end

        it 'should sign the encrypted payload' do
          machine_file = MachineCheckoutService.call(
            account: account,
            machine: machine,
            encrypt: true,
          )

          cert    = machine_file.certificate
          payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                        .delete_suffix("-----END MACHINE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify(digest, sig_bytes, "machine/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end
    end
  end

  context 'when the signing scheme is nil' do
    let(:license) { create(:license, account: account) }

    context 'when the machine file is not encrypted' do
      it 'should have a correct algorithm' do
        machine_file = MachineCheckoutService.call(
          account: account,
          machine: machine,
        )

        cert    = machine_file.certificate
        payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                      .delete_suffix("-----END MACHINE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        expect(json).to include(
          'alg' => 'base64+ed25519'
        )
      end

      it 'should sign the encoded payload' do
        machine_file = MachineCheckoutService.call(
          account: account,
          machine: machine,
        )

        cert    = machine_file.certificate
        payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                      .delete_suffix("-----END MACHINE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        enc       = json.fetch('enc')
        sig       = json.fetch('sig')
        sig_bytes = Base64.strict_decode64(sig)

        verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
        verify     = -> {
          verify_key.verify(sig_bytes, "machine/#{enc}")
        }

        expect { verify.call }.to_not raise_error
        expect(verify.call).to be true
      end
    end

    context 'when the machine file is encrypted' do
      it 'should have a correct algorithm' do
        machine_file = MachineCheckoutService.call(
          account: account,
          machine: machine,
          encrypt: true,
        )

        cert    = machine_file.certificate
        payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                      .delete_suffix("-----END MACHINE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        expect(json).to include(
          'alg' => 'aes-256-gcm+ed25519'
        )
      end

      it 'should sign the encrypted payload' do
        machine_file = MachineCheckoutService.call(
          account: account,
          machine: machine,
          encrypt: true,
        )

        cert    = machine_file.certificate
        payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                      .delete_suffix("-----END MACHINE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        enc       = json.fetch('enc')
        sig       = json.fetch('sig')
        sig_bytes = Base64.strict_decode64(sig)

        verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
        verify     = -> {
          verify_key.verify(sig_bytes, "machine/#{enc}")
        }

        expect { verify.call }.to_not raise_error
        expect(verify.call).to be true
      end
    end
  end

  context 'when using encryption' do
    it 'should return an encoded JSON payload' do
      machine_file = MachineCheckoutService.call(
        account: account,
        machine: machine,
      )

      cert = machine_file.certificate
      dec  = nil
      enc  = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                 .delete_suffix("-----END MACHINE FILE-----\n")

      expect { dec = Base64.decode64(enc) }.to_not raise_error
      expect(dec).to_not be_nil

      json = nil

      expect { json = JSON.parse(dec) }.to_not raise_error
      expect(json).to_not be_nil
      expect(json).to include(
        'enc' => a_kind_of(String),
        'sig' => a_kind_of(String),
        'alg' => a_kind_of(String),
      )
    end

    it 'should return an encrypted machine' do
      machine_file = MachineCheckoutService.call(
        account: account,
        machine: machine,
        encrypt: true,
      )

      cert    = machine_file.certificate
      payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                    .delete_suffix("-----END MACHINE FILE-----\n")

      json    = JSON.parse(Base64.decode64(payload))
      enc     = json.fetch('enc')
      decrypt = -> {
        aes = OpenSSL::Cipher::AES256.new(:GCM)
        aes.decrypt

        key            = OpenSSL::Digest::SHA256.digest(machine.fingerprint)
        ciphertext,
        iv,
        auth_tag       = enc.split('.')
                            .map { Base64.strict_decode64(_1) }

        aes.key = key
        aes.iv  = iv

        aes.auth_tag  = auth_tag
        aes.auth_data = ''

        plaintext = aes.update(ciphertext) + aes.final

        JSON.parse(plaintext)
      }

      expect { decrypt.call }.to_not raise_error

      data = decrypt.call

      expect(data).to_not be_nil
      expect(data).to include(
        'meta' => include(
        'issued' => machine_file.issued_at.iso8601(3),
        'expiry' => machine_file.expires_at.iso8601(3),
        'ttl' => machine_file.ttl,
      ),
        'data' => include(
          'type' => 'machines',
          'id' => machine.id,
        ),
      )
    end
  end

  context 'when including relationships' do
    it 'should not return the included relationships' do
      machine_file = MachineCheckoutService.call(
        account: account,
        machine: machine,
        include: [],
      )

      cert    = machine_file.certificate
      payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                    .delete_suffix("-----END MACHINE FILE-----\n")

      json = JSON.parse(Base64.decode64(payload))
      enc  = json.fetch('enc')
      data = nil

      expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

      expect(data).to_not be_nil
      expect(data).to_not have_key('included')
      expect(data).to include(
        'meta' => include(
          'issued' => machine_file.issued_at.iso8601(3),
          'expiry' => machine_file.expires_at.iso8601(3),
          'ttl' => machine_file.ttl,
        ),
        'data' => include(
          'type' => 'machines',
          'id' => machine.id,
        ),
      )
    end

    it 'should return the included relationships' do
      machine_file = MachineCheckoutService.call(
        account: account,
        machine: machine,
        include: %w[
          license.product
          license.policy
          license
        ],
      )

      cert    = machine_file.certificate
      payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                    .delete_suffix("-----END MACHINE FILE-----\n")

      json = JSON.parse(Base64.decode64(payload))
      enc  = json.fetch('enc')
      data = nil

      expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

      expect(data).to_not be_nil
      expect(data).to include(
        'included' => include(
          include('type' => 'products', 'id' => machine.product.id),
          include('type' => 'policies', 'id' => machine.policy.id),
          include('type' => 'licenses', 'id' => machine.license.id),
        ),
        'meta' => include(
          'issued' => machine_file.issued_at.iso8601(3),
          'expiry' => machine_file.expires_at.iso8601(3),
          'ttl' => machine_file.ttl,
        ),
        'data' => include(
          'type' => 'machines',
          'id' => machine.id,
        ),
      )
    end
  end

  context 'when using a TTL' do
    it 'should return a cert that expires after the default TTL' do
      freeze_time do
        machine_file = MachineCheckoutService.call(
          account: account,
          machine: machine,
        )

        cert    = machine_file.certificate
        payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                      .delete_suffix("-----END MACHINE FILE-----\n")

        json = JSON.parse(Base64.decode64(payload))
        enc  = json.fetch('enc')
        data = nil

        expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

        expect(data).to_not be_nil
        expect(data).to include(
          'meta' => include(
            'issued' => Time.current,
            'expiry' => 1.month.from_now,
            'ttl' => 1.month,
          ),
        )
      end
    end

    it 'should return a cert that expires after a custom TTL' do
      freeze_time do
        machine_file = MachineCheckoutService.call(
          account: account,
          machine: machine,
          ttl: 1.week,
        )

        cert    = machine_file.certificate
        payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                      .delete_suffix("-----END MACHINE FILE-----\n")

        json = JSON.parse(Base64.decode64(payload))
        enc  = json.fetch('enc')
        data = nil

        expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

        expect(data).to_not be_nil
        expect(data).to include(
          'meta' => include(
            'issued' => Time.current,
            'expiry' => 1.week.from_now,
            'ttl' => 1.week,
          ),
        )
      end
    end

    it 'should return a cert that has no TTL' do
      freeze_time do
        machine_file = MachineCheckoutService.call(
          account: account,
          machine: machine,
          ttl: nil,
        )

        cert    = machine_file.certificate
        payload = cert.delete_prefix("-----BEGIN MACHINE FILE-----\n")
                      .delete_suffix("-----END MACHINE FILE-----\n")

        json = JSON.parse(Base64.decode64(payload))
        enc  = json.fetch('enc')
        data = nil

        expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

        expect(data).to_not be_nil
        expect(data).to include(
          'meta' => include(
            'issued' => Time.current,
            'expiry' => nil,
            'ttl' => nil,
          ),
        )
      end
    end
  end
end
