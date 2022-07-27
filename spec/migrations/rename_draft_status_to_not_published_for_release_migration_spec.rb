# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameDraftStatusToNotPublishedForReleaseMigration do
  let(:account)                  { create(:account) }
  let(:product)                  { create(:product, account:) }
  let(:release_with_artifact)    { create(:release, :published, account:, product:, artifacts: [build(:artifact)]) }
  let(:release_without_artifact) { create(:release, :draft, account:, product:) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameDraftStatusToNotPublishedForReleaseMigration],
      }
    end
  end

  context 'the release does not have an artifact' do
    subject { release_without_artifact }

    it "should migrate a release's status" do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to include(
        data: include(
          attributes: include(
            status: 'DRAFT',
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          attributes: include(
            status: 'NOT_PUBLISHED',
          ),
        ),
      )
    end
  end

  context 'the release has an artifact' do
    subject { release_with_artifact }

    it "should not migrate a release's status" do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to include(
        data: include(
          attributes: include(
            status: 'PUBLISHED',
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          attributes: include(
            status: 'PUBLISHED',
          ),
        ),
      )
    end
  end
end
