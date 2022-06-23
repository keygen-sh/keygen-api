# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe AddKeyAttributeToArtifactsMigration do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }
  let(:release) { create(:release, account:, product:) }

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
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [AddKeyAttributeToArtifactsMigration],
      }
    end
  end

  it 'should migrate artifact attributes' do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render([
      create(:artifact, filename: '1', account:, release:),
      create(:artifact, filename: '2', account:, release:),
    ])

    expect(data).to_not include(
      data: [
        include(
          attributes: include(
            key: anything,
          ),
        ),
        include(
          attributes: include(
            key: anything,
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          attributes: include(
            key: '1',
          ),
        ),
        include(
          attributes: include(
            key: '2',
          ),
        ),
      ],
    )
  end
end
