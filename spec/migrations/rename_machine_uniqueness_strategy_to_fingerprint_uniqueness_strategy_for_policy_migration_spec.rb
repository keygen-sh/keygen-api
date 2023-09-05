# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameMachineUniquenessStrategyToFingerprintUniquenessStrategyForPolicyMigration do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  subject {
    create(:policy, account:, product:, machine_uniqueness_strategy: 'UNIQUE_PER_PRODUCT')
  }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameMachineUniquenessStrategyToFingerprintUniquenessStrategyForPolicyMigration],
      }
    end
  end

  it "should migrate a policy's machine uniqueness strategy" do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render(subject)

    expect(data).to include(
      data: include(
        attributes: include(
          machineUniquenessStrategy: 'UNIQUE_PER_PRODUCT',
        ),
      ),
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: include(
        attributes: include(
          fingerprintUniquenessStrategy: 'UNIQUE_PER_PRODUCT',
        ),
      ),
    )
  end
end
