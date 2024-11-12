# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseKeyLookupService do
  let(:account) { create(:account) }

  context 'when key is a legacy encrypted key' do
    let(:key)        { 'bdcecdc23c0f48229f77357151d1e67f-8e1ae3236636bfe57893b835871553eb-524ffec53ad05c14bbf3339eec741300-295512a0539cd0863abe42ddc29cf9v1' }
    let(:license_id) { key.split('-').first }

    context 'when key is a good key' do
      let(:digest) { '$2a$12$kh33FHu.TWYMZlWldcOMKet4YiVNqMHq8/A343/GTfPz.NRCPq2Q.' }

      subject! {
        create(:license, id: license_id, key: digest, account:)
      }

      it 'should fail unencrypted lookup' do
        record = described_class.call(key:, account:)

        expect(record).to be nil
      end

      it 'should pass encrypted lookup' do
        record = described_class.call(key:, account:, legacy_encrypted: true)

        expect(record).to eq subject
      end

      it 'should not rehash' do
        expect { described_class.call(key:, account:, legacy_encrypted: true) }.to_not(
          change { subject.reload.key },
        )
      end
    end

    context 'when key is a bad key' do
      let(:digest) { '$2a$12$kh33FHu.TWYMZlWldcOMKevM0Jj4VrN/8.EbfAj4cBEcS51A7hYUK' }

      subject!{
        create(:license, id: license_id, key: digest, account:)
      }

      it 'should fail unencrypted lookup' do
        record = described_class.call(key:, account:)

        expect(record).to be nil
      end

      it 'should pass encrypted lookup' do
        record = described_class.call(key:, account:, legacy_encrypted: true)

        expect(record).to eq subject
      end

      it 'should rehash' do
        expect { described_class.call(key:, account:, legacy_encrypted: true) }.to(
          change { subject.reload.key },
        )

        # sanity check
        ok = subject.compare_hashed_token(:key, key, version: 'v1')
        expect(ok).to be true
      end
    end
  end

  context 'when key is a normal key' do
    let(:key) { 'FC1ECF-659627-58D58E-42130E-ADD88F-V3' }

    subject! {
      create(:license, key:, account:)
    }

    it 'should pass unencrypted lookup' do
      record = described_class.call(key:, account:)

      expect(record).to eq subject
    end

    it 'should fail encrypted lookup' do
      record = described_class.call(key:, account:, legacy_encrypted: true)

      expect(record).to be nil
    end

    it 'should not rehash' do
      expect { described_class.call(key:, account:) }.to_not(
        change { subject.reload.key },
      )
    end
  end

  context 'when key is invalid' do
    let(:key) { '6798CE-A9478B-42027F-4046E8-3FFD66-V3' }

    it 'should fail unencrypted lookup' do
      record = described_class.call(key:, account:)

      expect(record).to be nil
    end

    it 'should fail encrypted lookup' do
      record = described_class.call(key:, account:, legacy_encrypted: true)

      expect(record).to be nil
    end
  end
end
