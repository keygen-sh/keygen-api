# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe AddProductRelationshipToArtifactMigration do
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
    Versionist.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [AddProductRelationshipToArtifactMigration],
      }
    end
  end

  it 'should migrate artifact relationship' do
    migrator = Versionist::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render(
      create(:artifact, account:, release:),
    )

    expect(data).to_not include(
      data: include(
        relationships: include(
          product: anything,
        ),
      ),
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: include(
        relationships: include(
          product: include(
            links: include(related: v1_account_product_path(account, product)),
            data: include(type: :products, id: product.id),
          ),
        ),
      ),
    )
  end
end
