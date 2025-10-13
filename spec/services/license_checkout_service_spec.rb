# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseCheckoutService do
  let(:account) { create(:account) }
  let(:license) { create(:license, account: account) }

  it 'should return a valid license file certificate' do
    license_file = LicenseCheckoutService.call(
      account: account,
      license: license,
    )

    expect { license_file.validate! }.to_not raise_error
    expect(license_file.account_id).to eq account.id
    expect(license_file.license_id).to eq license.id

    cert = license_file.certificate

    expect(cert).to start_with "-----BEGIN LICENSE FILE-----\n"
    expect(cert).to end_with "-----END LICENSE FILE-----\n"
  end

  it 'should return an encoded JSON payload' do
    license_file = LicenseCheckoutService.call(
      account: account,
      license: license,
    )

    cert = license_file.certificate
    dec =  nil
    enc =  cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
               .delete_suffix("-----END LICENSE FILE-----\n")

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

  it 'should return an encoded license' do
    license_file = LicenseCheckoutService.call(
      account: account,
      license: license,
    )

    cert    = license_file.certificate
    payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                  .delete_suffix("-----END LICENSE FILE-----\n")

    json = JSON.parse(Base64.decode64(payload))
    enc  = json.fetch('enc')
    data = nil

    expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

    expect(data).to_not be_nil
    expect(data).to include(
      'meta' => include(
        'issued' => license_file.issued_at.iso8601(3),
        'expiry' => license_file.expires_at.iso8601(3),
        'ttl' => license_file.ttl,
      ),
      'data' => include(
        'type' => 'licenses',
        'id' => license.id,
      ),
    )
  end

  context 'when invalid parameters are supplied to the service' do
    it 'should raise an error when account is nil' do
      checkout = -> {
        LicenseCheckoutService.call(
          account: nil,
          license: license,
        )
      }

      expect { checkout.call }.to raise_error LicenseCheckoutService::InvalidAccountError
    end

    it 'should raise an error when license is nil' do
      checkout = -> {
        LicenseCheckoutService.call(
          account: account,
          license: nil,
        )
      }

      expect { checkout.call }.to raise_error LicenseCheckoutService::InvalidLicenseError
    end

    it 'should raise an error when includes are invalid' do
      checkout = -> {
        LicenseCheckoutService.call(
          account: account,
          license: license,
          include: %w[
            account
          ]
        )
      }

      expect { checkout.call }.to raise_error LicenseCheckoutService::InvalidIncludeError
    end

    it 'should raise an error when TTL is too short' do
      checkout = -> {
        LicenseCheckoutService.call(
          account: account,
          license: license,
          ttl: 1.minute,
        )
      }

      expect { checkout.call }.to raise_error LicenseCheckoutService::InvalidTTLError
    end

    it 'should raise an error when algorithm is invalid' do
      checkout = -> {
        LicenseCheckoutService.call(
          algorithm: 'foo+bar',
          account:,
          license:,
        )
      }

      expect { checkout.call }.to raise_error LicenseCheckoutService::InvalidAlgorithmError
    end
  end

  %w[
    aes-256-gcm+ed25519
    aes-256-gcm+rsa-pss-sha256
    aes-256-gcm+rsa-sha256
    base64+ed25519
    base64+rsa-pss-sha256
    base64+rsa-sha256
  ].each do |algorithm|
    context "when the algorithm is #{algorithm}" do
      let(:license) { create(:license, account:) }

      it 'should have a correct algorithm' do
        license_file = LicenseCheckoutService.call(
          algorithm:,
          account:,
          license:,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        expect(json).to include(
          'alg' => algorithm,
        )
      end
    end
  end

  %w[
    ED25519_SIGN
  ].each do |scheme|
    context "when the signing scheme is #{scheme}" do
      let(:policy) { create(:policy, scheme.downcase.to_sym, account: account) }
      let(:license) { create(:license, policy: policy, account: account) }

      context 'when the license file is not encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'base64+ed25519'
          )
        end

        it 'should sign the encoded payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
          verify     = -> {
            verify_key.verify(sig_bytes, "license/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end

      context 'when the license file is encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'aes-256-gcm+ed25519'
          )
        end

        it 'should sign the encrypted payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
          verify     = -> {
            verify_key.verify(sig_bytes, "license/#{enc}")
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

      context 'when the license file is not encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'base64+rsa-pss-sha256'
          )
        end

        it 'should sign the encoded payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify_pss(digest, sig_bytes, "license/#{enc}", salt_length: :auto, mgf1_hash: 'SHA256')
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end

      context 'when the license file is encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'aes-256-gcm+rsa-pss-sha256'
          )
        end

        it 'should sign the encrypted payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify_pss(digest, sig_bytes, "license/#{enc}", salt_length: :auto, mgf1_hash: 'SHA256')
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

      context 'when the license file is not encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'base64+rsa-sha256'
          )
        end

        it 'should sign the encoded payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify(digest, sig_bytes, "license/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end

      context 'when the license file is encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'aes-256-gcm+rsa-sha256'
          )
        end

        it 'should sign the encrypted payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::RSA.new(account.public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify(digest, sig_bytes, "license/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end
    end
  end

  %w[
    ECDSA_P256_SIGN
  ].each do |scheme|
    context "when the signing scheme is #{scheme}" do
      let(:policy) { create(:policy, scheme.downcase.to_sym, account: account) }
      let(:license) { create(:license, policy: policy, account: account) }

      context 'when the license file is not encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'base64+ecdsa-p256'
          )
        end

        it 'should sign the encoded payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::EC.new(account.ecdsa_public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify(digest, sig_bytes, "license/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end

      context 'when the license file is encrypted' do
        it 'should have a correct algorithm' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          expect(json).to include(
            'alg' => 'aes-256-gcm+ecdsa-p256'
          )
        end

        it 'should sign the encrypted payload' do
          license_file = LicenseCheckoutService.call(
            account: account,
            license: license,
            encrypt: true,
          )

          cert    = license_file.certificate
          payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                        .delete_suffix("-----END LICENSE FILE-----\n")

          dec  = Base64.decode64(payload)
          json = JSON.parse(dec)

          enc       = json.fetch('enc')
          sig       = json.fetch('sig')
          sig_bytes = Base64.strict_decode64(sig)

          pub_key = OpenSSL::PKey::EC.new(account.ecdsa_public_key)
          digest  = OpenSSL::Digest::SHA256.new
          verify  = -> {
            pub_key.verify(digest, sig_bytes, "license/#{enc}")
          }

          expect { verify.call }.to_not raise_error
          expect(verify.call).to be true
        end
      end
    end
  end

  context 'when the signing scheme is nil' do
    let(:license) { create(:license, account: account) }

    context 'when the license file is not encrypted' do
      it 'should have a correct algorithm' do
        license_file = LicenseCheckoutService.call(
          account: account,
          license: license,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        expect(json).to include(
          'alg' => 'base64+ed25519'
        )
      end

      it 'should sign the encoded payload' do
        license_file = LicenseCheckoutService.call(
          account: account,
          license: license,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        enc       = json.fetch('enc')
        sig       = json.fetch('sig')
        sig_bytes = Base64.strict_decode64(sig)

        verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
        verify     = -> {
          verify_key.verify(sig_bytes, "license/#{enc}")
        }

        expect { verify.call }.to_not raise_error
        expect(verify.call).to be true
      end
    end

    context 'when the license file is encrypted' do
      it 'should have a correct algorithm' do
        license_file = LicenseCheckoutService.call(
          account: account,
          license: license,
          encrypt: true,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        expect(json).to include(
          'alg' => 'aes-256-gcm+ed25519'
        )
      end

      it 'should sign the encrypted payload' do
        license_file = LicenseCheckoutService.call(
          account: account,
          license: license,
          encrypt: true,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

        dec  = Base64.decode64(payload)
        json = JSON.parse(dec)

        enc       = json.fetch('enc')
        sig       = json.fetch('sig')
        sig_bytes = Base64.strict_decode64(sig)

        verify_key = Ed25519::VerifyKey.new([account.ed25519_public_key].pack('H*'))
        verify     = -> {
          verify_key.verify(sig_bytes, "license/#{enc}")
        }

        expect { verify.call }.to_not raise_error
        expect(verify.call).to be true
      end
    end
  end

  context 'when not using encryption' do
    it 'should return an encoded JSON payload' do
      license_file = LicenseCheckoutService.call(
        encrypt: false,
        account:,
        license:,
      )

      cert = license_file.certificate
      dec  = nil
      enc  = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                 .delete_suffix("-----END LICENSE FILE-----\n")

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

    it 'should return an unencrypted license' do
      license_file = LicenseCheckoutService.call(
        encrypt: false,
        account:,
        license:,
      )

      cert    = license_file.certificate
      payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                    .delete_suffix("-----END LICENSE FILE-----\n")

      json   = JSON.parse(Base64.decode64(payload))
      enc    = json.fetch('enc')
      decode = -> {
        dec = Base64.decode64(enc)

        JSON.parse(dec)
      }

      expect { decode.call }.to_not raise_error

      data = decode.call

      expect(data).to_not be_nil
      expect(data).to include(
        'meta' => include(
          'issued' => license_file.issued_at.iso8601(3),
          'expiry' => license_file.expires_at.iso8601(3),
          'ttl' => license_file.ttl,
        ),
        'data' => include(
          'type' => 'licenses',
          'id' => license.id,
        ),
      )
    end
  end

  context 'when using encryption' do
    it 'should return an encoded JSON payload' do
      license_file = LicenseCheckoutService.call(
        account: account,
        license: license,
        encrypt: true,
      )

      cert = license_file.certificate
      dec  = nil
      enc  = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                 .delete_suffix("-----END LICENSE FILE-----\n")

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

    it 'should return an encrypted license' do
      license_file = LicenseCheckoutService.call(
        account: account,
        license: license,
        encrypt: true,
      )

      cert    = license_file.certificate
      payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                    .delete_suffix("-----END LICENSE FILE-----\n")

      json    = JSON.parse(Base64.decode64(payload))
      enc     = json.fetch('enc')
      decrypt = -> {
        aes = OpenSSL::Cipher::AES256.new(:GCM)
        aes.decrypt

        key            = OpenSSL::Digest::SHA256.digest(license.key)
        ciphertext,
        iv,
        tag            = enc.split('.')
                            .map { Base64.strict_decode64(it) }

        aes.key = key
        aes.iv  = iv

        aes.auth_tag  = tag
        aes.auth_data = ''

        plaintext = aes.update(ciphertext) + aes.final

        JSON.parse(plaintext)
      }

      expect { decrypt.call }.to_not raise_error

      data = decrypt.call

      expect(data).to_not be_nil
      expect(data).to include(
        'meta' => include(
          'issued' => license_file.issued_at.iso8601(3),
          'expiry' => license_file.expires_at.iso8601(3),
          'ttl' => license_file.ttl,
        ),
        'data' => include(
          'type' => 'licenses',
          'id' => license.id,
        ),
      )
    end
  end

  context 'when including relationships' do
    it 'should not return the included relationships' do
      license_file = LicenseCheckoutService.call(
        account: account,
        license: license,
        include: [],
      )

      cert    = license_file.certificate
      payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                    .delete_suffix("-----END LICENSE FILE-----\n")

      json = JSON.parse(Base64.decode64(payload))
      enc  = json.fetch('enc')
      data = nil

      expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

      expect(data).to_not be_nil
      expect(data).to_not have_key('included')
      expect(data).to include(
        'meta' => include(
          'issued' => license_file.issued_at.iso8601(3),
          'expiry' => license_file.expires_at.iso8601(3),
          'ttl' => license_file.ttl,
        ),
        'data' => include(
          'type' => 'licenses',
          'id' => license.id,
        ),
      )
    end

    it 'should return the included relationships' do
      license_file = LicenseCheckoutService.call(
        account: account,
        license: license,
        include: %w[
          product
          policy
        ],
      )

      cert    = license_file.certificate
      payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                    .delete_suffix("-----END LICENSE FILE-----\n")

      json = JSON.parse(Base64.decode64(payload))
      enc  = json.fetch('enc')
      data = nil

      expect { data = JSON.parse(Base64.strict_decode64(enc)) }.to_not raise_error

      expect(data).to_not be_nil
      expect(data).to include(
        'included' => include(
          include('type' => 'products', 'id' => license.product.id),
          include('type' => 'policies', 'id' => license.policy.id),
        ),
        'meta' => include(
          'issued' => license_file.issued_at.iso8601(3),
          'expiry' => license_file.expires_at.iso8601(3),
          'ttl' => license_file.ttl,
        ),
        'data' => include(
          'type' => 'licenses',
          'id' => license.id,
        ),
      )
    end
  end

  context 'when using a TTL' do
    it 'should return a cert that expires after the default TTL' do
      freeze_time do
        license_file = LicenseCheckoutService.call(
          account: account,
          license: license,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

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
        license_file = LicenseCheckoutService.call(
          account: account,
          license: license,
          ttl: 1.week,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

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
        license_file = LicenseCheckoutService.call(
          account: account,
          license: license,
          ttl: nil,
        )

        cert    = license_file.certificate
        payload = cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                      .delete_suffix("-----END LICENSE FILE-----\n")

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
