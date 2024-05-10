# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameProcessLeasingStrategyToLeasingStrategyForPolicyMigration do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  subject {
    create(:policy, account:, product:, process_leasing_strategy: 'PER_MACHINE')
  }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameProcessLeasingStrategyToLeasingStrategyForPolicyMigration],
      }
    end
  end

  it "should migrate a policy's process leasing strategy" do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render(subject)

    expect(data).to include(
      data: include(
        attributes: include(
          processLeasingStrategy: 'PER_MACHINE',
        ),
      ),
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: include(
        attributes: include(
          leasingStrategy: 'PER_MACHINE',
        ),
      ),
    )
  end
end
