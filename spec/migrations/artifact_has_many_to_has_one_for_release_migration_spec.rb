# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ArtifactHasManyToHasOneForReleaseMigration do
  let(:account)                  { create(:account) }
  let(:product)                  { create(:product, account:) }
  let(:release_with_artifact)    { create(:release, :published, account:, product:, artifacts: [build(:artifact)]) }
  let(:release_without_artifact) { create(:release, :draft, account:, product:) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [ArtifactHasManyToHasOneForReleaseMigration],
      }
    end
  end

  context 'the release does not have an artifact' do
    subject { release_without_artifact }

    it 'should migrate a release artifact relationship' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to include(
        data: include(
          relationships: include(
            artifacts: {
              links: {
                related: v1_account_release_release_artifacts_path(subject.account_id, subject.id),
              },
            },
          )
        )
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          relationships: include(
            artifact: {
              data: nil,
              links: {
                related: v1_account_release_v1_0_release_artifact_path(subject.account_id, subject.id),
              },
            },
          )
        )
      )
    end
  end

  context 'the release has an artifact' do
    subject { release_with_artifact }

    it 'should migrate a release artifact relationship' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to include(
        data: include(
          relationships: include(
            artifacts: {
              links: {
                related: v1_account_release_release_artifacts_path(subject.account_id, subject.id),
              },
            },
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          relationships: include(
            artifact: {
              data: {
                type: :artifacts,
                id: subject.artifacts.sole.id,
              },
              links: {
                related: v1_account_release_v1_0_release_artifact_path(subject.account_id, subject.id),
              },
            },
          ).and(
            exclude(
              artifacts: anything,
            ),
          ),
        ),
      )
    end
  end
end
