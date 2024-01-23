# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

shared_examples :encryptable do
  let(:factory) { described_class.name.demodulize.underscore }
  let(:account) { create(:account) }
  let(:record)  { create(factory, account:) }

  non_deterministic_encrypted_attributes =
    described_class.encrypted_attributes - described_class.deterministic_encrypted_attributes

  hash_digest_classes = [
    # The default for Rails >= 7.1 (see https://github.com/rails/rails/issues/48204)
    OpenSSL::Digest::SHA256,
    # The default for Rails <= 7.0
    OpenSSL::Digest::SHA1,
  ]

  # FIXME(ezekg) Tests config.active_record.encryption.support_sha1_for_non_deterministic_encryption.
  #              Delete this test after we re-encrypt our data.
  hash_digest_classes.each do |hash_digest_class|
    context "with #{hash_digest_class.name} non-determinstically encrypted attributes" do
      non_deterministic_encrypted_attributes.each do |encrypted_attribute|
        it "should decrypt #{encrypted_attribute.inspect}" do
          primary_key   = Rails.application.config.active_record.encryption.primary_key
          key_generator = ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class:)
          key_provider  = ActiveRecord::Encryption::DerivedSecretKeyProvider.new(primary_key, key_generator:)
          encryptor     = ActiveRecord::Encryption::Encryptor.new

          dec = record.read_attribute(encrypted_attribute)
          enc = encryptor.encrypt(dec, key_provider:)

          described_class.connection.exec_update(
            described_class.sanitize_sql(
              [
                "UPDATE #{described_class.table_name} SET #{encrypted_attribute} = :value WHERE id = :id",
                {
                  id: record.id,
                  value: enc,
                },
              ],
            ),
          )

          expect { record.reload.read_attribute(encrypted_attribute) }.to_not raise_error
          expect(record.read_attribute(encrypted_attribute) ).to eq dec
        end
      end
    end
  end
end
