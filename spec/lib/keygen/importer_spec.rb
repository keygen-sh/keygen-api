# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keygen'

describe Keygen::Importer do
  let(:account)  { create(:account) }

  before do
    create_list(:user, rand(1..100), account:)
    create_list(:license, rand(1..100), account:)
    create_list(:machine, rand(1..100), account:)
  end

  context 'with encryption' do
    let(:secret_key) { SecureRandom.hex }

    it 'should import' do
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
  end

  context 'without encryption' do
    it 'should import' do
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
  end
end
