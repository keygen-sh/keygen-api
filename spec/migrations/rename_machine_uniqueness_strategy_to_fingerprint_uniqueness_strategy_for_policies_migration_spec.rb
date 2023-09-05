# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameMachineUniquenessStrategyToFingerprintUniquenessStrategyForPoliciesMigration do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  subject {
    [
      create(:policy, account:, product:, machine_uniqueness_strategy: 'UNIQUE_PER_ACCOUNT'),
      create(:policy, account:, product:, machine_uniqueness_strategy: 'UNIQUE_PER_PRODUCT'),
      create(:policy, account:, product:, machine_uniqueness_strategy: 'UNIQUE_PER_POLICY'),
    ]
  }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameMachineUniquenessStrategyToFingerprintUniquenessStrategyForPoliciesMigration],
      }
    end
  end

  it "should migrate policies' machine uniqueness strategy" do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render(subject)

    expect(data).to include(
      data: [
        include(
          attributes: include(
            machineUniquenessStrategy: 'UNIQUE_PER_ACCOUNT',
          ),
        ),
        include(
          attributes: include(
            machineUniquenessStrategy: 'UNIQUE_PER_PRODUCT',
          ),
        ),
        include(
          attributes: include(
            machineUniquenessStrategy: 'UNIQUE_PER_POLICY',
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          attributes: include(
            fingerprintUniquenessStrategy: 'UNIQUE_PER_ACCOUNT',
          ),
        ),
        include(
          attributes: include(
            fingerprintUniquenessStrategy: 'UNIQUE_PER_PRODUCT',
          ),
        ),
        include(
          attributes: include(
            fingerprintUniquenessStrategy: 'UNIQUE_PER_POLICY',
          ),
        ),
      ],
    )
  end
end
