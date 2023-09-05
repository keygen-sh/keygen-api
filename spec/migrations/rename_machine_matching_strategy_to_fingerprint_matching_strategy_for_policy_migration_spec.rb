# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameMachineMatchingStrategyToFingerprintMatchingStrategyForPolicyMigration do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  subject {
    create(:policy, account:, product:, machine_matching_strategy: 'MATCH_TWO')
  }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameMachineMatchingStrategyToFingerprintMatchingStrategyForPolicyMigration],
      }
    end
  end

  it "should migrate a policy's machine matching strategy" do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render(subject)

    expect(data).to include(
      data: include(
        attributes: include(
          machineMatchingStrategy: 'MATCH_TWO',
        ),
      ),
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: include(
        attributes: include(
          fingerprintMatchingStrategy: 'MATCH_TWO',
        ),
      ),
    )
  end
end
