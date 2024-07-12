# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keygen'

describe Keygen::Importer do
  let(:account)  { create(:account) }

  it 'should not raise for valid io', :ignore_potential_false_positives do
    expect { Keygen::Importer.import(from: StringIO.new) }
      .to_not raise_error ArgumentError
  end

  it 'should raise for invalid io' do
    expect { Keygen::Importer.import(from: '') }
      .to raise_error ArgumentError
  end

  it 'should not raise for valid version 1' do
    expect { Keygen::Importer.import(from: StringIO.new(1.chr)) }
      .to_not raise_error
  end

  it 'should raise for invalid version' do
    expect { Keygen::Importer.import(from: StringIO.new(42.chr)) }
      .to raise_error Keygen::Importer::UnsupportedVersionError
  end

  it 'should raise for invalid data' do
    data = 'zzz'
    size = [data.bytesize].pack('Q>')

    expect { Keygen::Importer.import(from: StringIO.new(1.chr + size + data)) }
      .to raise_error Keygen::Importer::InvalidDataError
  end

  it 'should raise for invalid chunk' do
    data = 'zz'
    size = ['zzz'.bytesize].pack('Q>')

    expect { Keygen::Importer.import(from: StringIO.new(1.chr + size + data)) }
      .to raise_error Keygen::Importer::InvalidChunkError
  end

  context 'with encryption' do
    let(:secret_key) { SecureRandom.hex }

    before do
      create_list(:user, rand(1..100), account:)
      create_list(:license, rand(1..100), account:)
      create_list(:machine, rand(1..100), account:)
    end

    it 'should import with valid secret key' do
      export = Keygen::Exporter.export(account, secret_key:)

      user_count_was    = account.users.all.delete_all
      license_count_was = account.licenses.all.delete_all
      machine_count_was = account.machines.all.delete_all
      account.delete

      expect { Keygen::Importer.import(from: export, secret_key:) }.to change { Account.count }.by(1)
        .and change { User.count }.by(user_count_was)
        .and change { License.count }.by(license_count_was)
        .and change { Machine.count }.by(machine_count_was)
    end

    it 'should raise with invalid secret key' do
      export = Keygen::Exporter.export(account, secret_key:)

      expect { Keygen::Importer.import(from: export, secret_key: 'invalid') }
        .to raise_error Keygen::Importer::InvalidSecretKeyError
    end
  end

  context 'without encryption' do
    before do
      create_list(:user, rand(1..100), account:)
      create_list(:license, rand(1..100), account:)
      create_list(:machine, rand(1..100), account:)
    end

    it 'should import without secret key' do
      export = Keygen::Exporter.export(account)

      user_count_was    = account.users.all.delete_all
      license_count_was = account.licenses.all.delete_all
      machine_count_was = account.machines.all.delete_all
      account.delete

      expect { Keygen::Importer.import(from: export) }.to change { Account.count }.by(1)
        .and change { User.count }.by(user_count_was)
        .and change { License.count }.by(license_count_was)
        .and change { Machine.count }.by(machine_count_was)
    end

    it 'should raise with secret key' do
      export = Keygen::Exporter.export(account)

      expect { Keygen::Importer.import(from: export, secret_key: 'invalid') }
        .to raise_error Keygen::Importer::InvalidSecretKeyError
    end
  end
end
