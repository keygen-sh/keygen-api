# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe ArtifactHasManyToHasOneForReleasesMigration do
  let(:account)                  { create(:account) }
  let(:product)                  { create(:product, account:) }
  let(:release_without_artifact) { create(:release, :unpublished, account:, product:) }
  let(:release_with_artifact)    { create(:release, :published, account:, product:) }

  before do
    Sidekiq::Testing.fake!
    StripeHelper.start
  end

  after do
    DatabaseCleaner.clean
    StripeHelper.stop
  end

  before do
    Versionist.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [ArtifactHasManyToHasOneForReleasesMigration],
      }
    end
  end

  it 'should migrate releases artifact relationships' do
    migrator = Versionist::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render([
      release_without_artifact,
      release_with_artifact,
    ])

    expect(data).to include(
      data: [
        include(
          relationships: include(
            artifacts: {
              links: {
                related: v1_account_release_artifacts_path(release_without_artifact.account_id, release_without_artifact.id),
              },
            },
          ),
        ),
        include(
          relationships: include(
            artifacts: {
              links: {
                related: v1_account_release_artifacts_path(release_with_artifact.account_id, release_with_artifact.id),
              },
            },
          ),
        ),
      ]
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          relationships: include(
            artifact: {
              data: nil,
              links: {
                related: v1_account_release_legacy_artifact_path(release_without_artifact.account_id, release_without_artifact.id),
              },
            },
          )
        ),
        include(
          relationships: include(
            artifact: {
              data: {
                type: 'artifacts',
                id: release_with_artifact.artifacts.sole.id,
              },
              links: {
                related: v1_account_release_legacy_artifact_path(release_with_artifact.account_id, release_with_artifact.id),
              },
            },
          )
        ),
      ]
    )
  end
end
