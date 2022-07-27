# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe AddConcurrentAttributeToPoliciesMigration do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.1'
      config.versions        = {
        '1.1' => [AddConcurrentAttributeToPoliciesMigration],
      }
    end
  end

  it "should migrate policy attributes" do
    migrator = RequestMigrations::Migrator.new(from: '1.1', to: '1.1')
    data     = Keygen::JSONAPI.render([
      create(:policy, :floating, overage_strategy: 'ALWAYS_ALLOW_OVERAGE', account:, product:),
      create(:policy, :floating, overage_strategy: 'ALLOW_1_25X_OVERAGE', account:, product:),
      create(:policy, :floating, overage_strategy: 'ALLOW_1_5X_OVERAGE', account:, product:),
      create(:policy, :floating, overage_strategy: 'ALLOW_2X_OVERAGE', account:, product:),
      create(:policy, :floating, overage_strategy: 'NO_OVERAGE', account:, product:),
    ])

    expect(data).to_not include(
      data: [
        include(
          attributes: include(
            concurrent: anything,
          ),
        ),
        include(
          attributes: include(
            concurrent: anything,
          ),
        ),
        include(
          attributes: include(
            concurrent: anything,
          ),
        ),
        include(
          attributes: include(
            concurrent: anything,
          ),
        ),
        include(
          attributes: include(
            concurrent: anything,
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          attributes: include(
            concurrent: true,
          ),
        ),
        include(
          attributes: include(
            concurrent: true,
          ),
        ),
        include(
          attributes: include(
            concurrent: true,
          ),
        ),
        include(
          attributes: include(
            concurrent: true,
          ),
        ),
        include(
          attributes: include(
            concurrent: false,
          ),
        ),
      ],
    )
  end
end
