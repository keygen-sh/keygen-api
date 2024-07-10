# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keygen'

describe Keygen::Exporter do
  let(:account) { create(:account) }

  before do
    create_list(:user, 5, account:)
    create_list(:license, 5, account:)
    create_list(:machine, 5, account:)
  end

  context 'with encryption' do
    let(:secret_key) { SecureRandom.hex }

    it 'should export' do
      export = Keygen::Exporter.export(account, to: StringIO.new, secret_key:)

      expect(export.size).to be > 1.byte
    end

    it 'should be versioned' do
      export  = Keygen::Exporter.export(account, to: StringIO.new, secret_key:)
      version = export.read(1).unpack1('C')

      expect(version).to eq Keygen::Exporter::VERSION
    end

    it 'should be importable' do
      export = Keygen::Exporter.export(account, to: StringIO.new, secret_key:)

      expect { Keygen::Importer.import(from: export, secret_key:) }.to_not raise_error
    end
  end

  context 'without encryption' do
    it 'should export' do
      export = Keygen::Exporter.export(account, to: StringIO.new)

      expect(export.size).to be > 1.byte
    end

    it 'should be versioned' do
      export  = Keygen::Exporter.export(account, to: StringIO.new)
      version = export.read(1).unpack1('C')

      expect(version).to eq Keygen::Exporter::VERSION
    end

    it 'should be importable' do
      export = Keygen::Exporter.export(account, to: StringIO.new)

      expect { Keygen::Importer.import(from: export) }.to_not raise_error
    end
  end
end
