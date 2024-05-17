# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keygen'

describe Keygen::Importer do
  let(:account)    { create(:account) }
  let(:account_id) { account.id }

  # run association async destroys inline
  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  around do |example|
    perform_enqueued_jobs { example.run }
  end

  it 'should not raise for valid io', :ignore_potential_false_positives do
    expect { Keygen::Importer.import(account_id:, from: StringIO.new) }
      .to_not raise_error ArgumentError
  end

  it 'should raise for invalid io' do
    expect { Keygen::Importer.import(account_id:, from: '') }
      .to raise_error ArgumentError
  end

  it 'should not raise for valid version 1' do
    expect { Keygen::Importer.import(account_id:, from: StringIO.new(1.chr)) }
      .to_not raise_error
  end

  it 'should raise for invalid version' do
    expect { Keygen::Importer.import(account_id:, from: StringIO.new(42.chr)) }
      .to raise_error Keygen::Importer::UnsupportedVersionError
  end

  it 'should raise for invalid data' do
    data = 'zzz'
    size = [data.bytesize].pack('Q>')

    expect { Keygen::Importer.import(account_id:, from: StringIO.new(1.chr + size + data)) }
      .to raise_error Keygen::Importer::InvalidDataError
  end

  it 'should raise for invalid chunk' do
    data = 'zz'
    size = ['zzz'.bytesize].pack('Q>')

    expect { Keygen::Importer.import(account_id:, from: StringIO.new(1.chr + size + data)) }
      .to raise_error Keygen::Importer::InvalidChunkError
  end

  context 'with encryption' do
    let(:secret_key) { SecureRandom.hex }

    before do
      create_list(:user, 5, account:)
      create_list(:license, 5, account:)
      create_list(:machine, 5, account:)
    end

    it 'should import with valid secret key' do
      export = Keygen::Exporter.export(account, secret_key:)

      user_count_was    = account.users.count
      license_count_was = account.licenses.count
      machine_count_was = account.machines.count
      account.destroy!

      expect { Keygen::Importer.import(from: export, account_id:, secret_key:) }.to change { Account.count }.by(1)
        .and change { User.count }.by(user_count_was)
        .and change { License.count }.by(license_count_was)
        .and change { Machine.count }.by(machine_count_was)
    end

    it 'should raise with invalid secret key' do
      export = Keygen::Exporter.export(account, secret_key:)
      account.destroy!

      expect { Keygen::Importer.import(from: export, secret_key: 'invalid', account_id:) }
        .to raise_error Keygen::Importer::InvalidSecretKeyError
    end
  end

  context 'without encryption' do
    before do
      create_list(:user, 5, account:)
      create_list(:license, 5, account:)
      create_list(:machine, 5, account:)
    end

    it 'should import without secret key' do
      export = Keygen::Exporter.export(account)

      user_count_was    = account.users.count
      license_count_was = account.licenses.count
      machine_count_was = account.machines.count
      account.destroy!

      expect { Keygen::Importer.import(from: export, account_id:) }.to change { Account.count }.by(1)
        .and change { User.count }.by(user_count_was)
        .and change { License.count }.by(license_count_was)
        .and change { Machine.count }.by(machine_count_was)
    end

    it 'should raise with secret key' do
      export = Keygen::Exporter.export(account)
      account.destroy!

      expect { Keygen::Importer.import(from: export, secret_key: 'invalid', account_id:) }
        .to raise_error Keygen::Importer::InvalidSecretKeyError
    end
  end

  context 'with invalid account' do
    let(:other_account)    { create(:account) }
    let(:other_account_id) { other_account.id }

    it 'should raise for unexpected account' do
      export = Keygen::Exporter.export(account)
      account.destroy!

      expect { Keygen::Importer.import(from: export, account_id: SecureRandom.uuid) }
        .to raise_error Keygen::Importer::InvalidAccountError
    end

    it 'should raise for duplicate account' do
      export = Keygen::Exporter.export(account)

      expect { Keygen::Importer.import(from: export, account_id:) }
        .to raise_error Keygen::Importer::DuplicateRecordError
    end

    it 'should raise for multiple accounts' do
      export_a = Keygen::Exporter.export(account)
      export_b = Keygen::Exporter.export(other_account)

      account.destroy!
      other_account.destroy!

      # skip version
      export_b.seek(1, IO::SEEK_SET)

      # splice exports together
      export = StringIO.new(export_a.read + export_b.read)

      expect { Keygen::Importer.import(from: export, account_id:) }
        .to raise_error Keygen::Importer::InvalidAccountError
    end
  end

  context 'with invalid record' do
    let(:other_account)    { create(:account) }
    let(:other_account_id) { other_account.id }

    before do
      create_list(:license, 5, account: other_account)
      create_list(:license, 5, account:)
    end

    it 'should raise for invalid record' do
      export_a = Keygen::Exporter.export(account)
      export_b = Keygen::Exporter.export(other_account)

      account.destroy! # destroy associations
      other_account.destroy!

      # skip version
      export_b.seek(1, IO::SEEK_SET)

      # skip account
      offset = export_b.read(8).unpack1('Q>')
      export_b.seek(offset, IO::SEEK_CUR)

      # splice exports together
      export = StringIO.new(export_a.read + export_b.read)

      expect { Keygen::Importer.import(from: export, account_id:) }
        .to raise_error Keygen::Importer::InvalidRecordError
    end

    it 'should raise for duplicate record' do
      export = Keygen::Exporter.export(account)

      account.delete # keep associations

      expect { Keygen::Importer.import(from: export, account_id:) }
        .to raise_error Keygen::Importer::DuplicateRecordError
    end

    it 'should raise on unsupported record' do
      export = Keygen::Exporter.export(account)
      account.destroy!

      # splice in an unsupported record
      chunk      = Keygen::Exporter::V1::Serializer.new.serialize(Plan.name, [{ id: SecureRandom.uuid }])
      chunk_size = [chunk.bytesize].pack('Q>')

      export.seek(0, IO::SEEK_END)
      export.write(chunk_size + chunk)
      export.seek(0, IO::SEEK_SET)

      expect { Keygen::Importer.import(from: export, account_id:) }
        .to raise_error Keygen::Importer::UnsupportedRecordError
    end
  end
end
