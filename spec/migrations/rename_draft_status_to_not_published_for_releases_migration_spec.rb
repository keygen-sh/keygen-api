# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe RenameDraftStatusToNotPublishedForReleasesMigration do
  let(:account)                  { create(:account) }
  let(:product)                  { create(:product, account:) }
  let(:release_with_artifact)    { create(:release, :published, account:, product:, artifacts: [build(:artifact)]) }
  let(:release_without_artifact) { create(:release, :draft, account:, product:) }

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
        '1.0' => [RenameDraftStatusToNotPublishedForReleasesMigration],
      }
    end
  end

  it 'should migrate releases statuses' do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render([
      release_without_artifact,
      release_with_artifact,
    ])

    expect(data).to include(
      data: [
        include(
          attributes: include(
            status: 'DRAFT',
          ),
        ),
        include(
          attributes: include(
            status: 'PUBLISHED',
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          attributes: include(
            status: 'NOT_PUBLISHED',
          ),
        ),
        include(
          attributes: include(
            status: 'PUBLISHED',
          ),
        ),
      ],
    )
  end
end
