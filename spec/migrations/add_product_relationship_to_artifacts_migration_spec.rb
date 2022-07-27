# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe AddProductRelationshipToArtifactsMigration do
  let(:account)     { create(:account) }
  let(:app)         { create(:product, account:) }
  let(:cli)         { create(:product, account:) }
  let(:app_release) { create(:release, account:, product: app) }
  let(:cli_release) { create(:release, account:, product: cli) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [AddProductRelationshipToArtifactsMigration],
      }
    end
  end

  it 'should migrate artifact relationships' do
    migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
    data     = Keygen::JSONAPI.render([
      create(:artifact, account:, release: app_release),
      create(:artifact, account:, release: cli_release),
    ])

    expect(data).to_not include(
      data: [
        include(
          relationships: include(
            product: anything,
          ),
        ),
        include(
          relationships: include(
            product: anything,
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          relationships: include(
            product: include(
              links: include(related: v1_account_product_path(account, app)),
              data: include(type: :products, id: app.id),
            ),
          ),
        ),
        include(
          relationships: include(
            product: include(
              links: include(related: v1_account_product_path(account, cli)),
              data: include(type: :products, id: cli.id),
            ),
          ),
        ),
      ],
    )
  end
end
