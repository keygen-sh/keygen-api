# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe ReleaseArtifact, type: :model do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.fake!
    StripeHelper.start
  end

  after do
    DatabaseCleaner.clean
    StripeHelper.stop
  end

  context 'when sorting by version' do
    before do
      versions = %w[
        1.0.0-beta
        1.0.0-beta.2
        1.0.0-beta+exp.sha.6
        1.0.0-alpha.beta
        1.0.0+20130313144700
        1.0.0-alpha
        1.0.0-beta.11
        1.0.0-alpha.1
        1.0.0
        1.0.0+21AF26D3
        1.0.0-beta+exp.sha.5114f85
        1.0.0-rc.1
        1.0.0-alpha+001
        1.0.1
        1.1.3
        1.1.21
        2.0.0
      ]

      releases  = versions.map { create(:release, :published, version: _1.to_s, product:, account:) }
      artifacts = releases.map { create(:artifact, :uploaded, release: _1, account:) }
    end

    it 'should sort by semver' do
      versions = ReleaseArtifact.order_by_version.pluck(:version)

      expect(versions).to eq %w[
        2.0.0
        1.1.21
        1.1.3
        1.0.1
        1.0.0+21AF26D3
        1.0.0+20130313144700
        1.0.0
        1.0.0-rc.1
        1.0.0-beta.11
        1.0.0-beta.2
        1.0.0-beta+exp.sha.5114f85
        1.0.0-beta+exp.sha.6
        1.0.0-beta
        1.0.0-alpha.beta
        1.0.0-alpha.1
        1.0.0-alpha+001
        1.0.0-alpha
      ]
    end
  end
end
