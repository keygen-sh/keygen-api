# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Diffable, type: :concern do
  let(:account) { create(:account) }
  let(:license) { create(:license, account:, name: 'foo') }

  describe '#to_diff' do
    it 'returns unfiltered changes for benign keys and values' do
      license.update!(name: 'bar')

      expect(license.to_diff).to include('name' => %w[foo bar])
    end

    it 'masks changes for sensitive keys' do
      license.update!(key: 'a' * 32)

      expect(license.to_diff).to include('key' => [a_string_matching(/\A.+\.\.\..+\z/), 'aaaa...aaaa'])
    end

    it 'masks changes for sensitive values under benign keys' do
      license.update!(name: "admin-#{'a1' * 32}v3")

      expect(license.to_diff).to include('name' => %w[foo admi...a1v3])
    end

    it 'masks only the sensitive side of a change' do
      license.update!(name: 'otpauth://totp/Keygen:user%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=Keygen')
      license.update!(name: 'bar')

      expect(license.to_diff).to include('name' => %w[otpa...ygen bar])
    end

    it 'removes suffixes from keys' do
      license.update!(expiry: 1.year.from_now, suspended: true)

      expect(license.to_diff.keys).to include('suspended', 'updated')
      expect(license.to_diff.keys).to_not include('updated_at')
    end
  end
end
