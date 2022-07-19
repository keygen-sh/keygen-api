# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: %w[permissions event_types] }

describe CopyArtifactAttributesToReleasesMigration do
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
        '1.0' => [CopyArtifactAttributesToReleasesMigration],
      }
    end
  end

  it 'should migrate release attributes' do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render([
      release_without_artifact,
      release_with_artifact,
    ])

    expect(data).to_not include(
      data: [
        include(
          attributes: include(
            platform: anything,
            filetype: anything,
            filename: anything,
            filesize: anything,
            signature: anything,
            checksum: anything,
          ),
        ),
        include(
          attributes: include(
            platform: anything,
            filetype: anything,
            filename: anything,
            filesize: anything,
            signature: anything,
            checksum: anything,
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          attributes: include(
            platform: nil,
            filetype: nil,
            filename: nil,
            filesize: nil,
            signature: nil,
            checksum: nil,
          ),
        ),
        include(
          attributes: include(
            platform: release_with_artifact.artifact.platform.key,
            filetype: release_with_artifact.artifact.filetype.key,
            filename: release_with_artifact.artifact.filename,
            filesize: release_with_artifact.artifact.filesize,
            signature: release_with_artifact.artifact.signature,
            checksum: release_with_artifact.artifact.checksum,
          ),
        ),
      ],
    )
  end
end
