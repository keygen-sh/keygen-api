# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe AddConcurrentAttributeToPolicyMigration do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  before do
    Sidekiq::Testing.fake!
    StripeHelper.start
  end

  after do
    DatabaseCleaner.clean
    StripeHelper.stop
  end

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.1'
      config.versions        = {
        '1.1' => [AddConcurrentAttributeToPolicyMigration],
      }
    end
  end

  context 'the policy does not allow overages' do
    subject { create(:policy, overage_strategy: 'NO_OVERAGE', account:, product:) }

    it "should migrate a policy's attributes" do
      migrator = RequestMigrations::Migrator.new(from: '1.1', to: '1.1')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to_not include(
        data: include(
          attributes: include(
            concurrent: anything,
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          attributes: include(
            concurrent: false,
          ),
        ),
      )
    end
  end

  context 'the policy does allow overages' do
    subject { create(:policy, overage_strategy: 'ALWAYS_ALLOW_OVERAGE', account:, product:) }

    it "should migrate a policy's attributes" do
      migrator = RequestMigrations::Migrator.new(from: '1.1', to: '1.1')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to_not include(
        data: include(
          attributes: include(
            concurrent: anything,
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          attributes: include(
            concurrent: true,
          ),
        ),
      )
    end
  end
end
