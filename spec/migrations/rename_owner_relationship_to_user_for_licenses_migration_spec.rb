# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameOwnerRelationshipToUserForLicensesMigration do
  let(:account)               { create(:account) }
  let(:license_without_owner) { create(:license, :without_owner, account:) }
  let(:license_with_owner)    { create(:license, :with_owner, account:) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = CURRENT_API_VERSION
      config.versions        = {
        '1.0' => [RenameOwnerRelationshipToUserForLicensesMigration],
      }
    end
  end

  it 'should migrate license owner relationships' do
    migrator = RequestMigrations::Migrator.new(from: CURRENT_API_VERSION, to: '1.0')
    data     = Keygen::JSONAPI.render(
      [
        license_without_owner,
        license_with_owner,
      ],
      api_version: CURRENT_API_VERSION,
      account:,
    )

    expect(data).to include(
      data: [
        include(
          relationships: include(
            owner: {
              data: nil,
              links: {
                related: v1_account_license_owner_path(license_without_owner.account_id, license_without_owner.id),
              },
            },
          ),
        ),
        include(
          relationships: include(
            owner: {
              data: { type: :users, id: license_with_owner.owner_id },
              links: {
                related: v1_account_license_owner_path(license_with_owner.account_id, license_with_owner.id),
              },
            },
          ),
        ),
      ],
    )

    migrator.migrate!(data:)

    expect(data).to include(
      data: [
        include(
          relationships: include(
            user: {
              data: nil,
              links: {
                related: v1_account_license_v1_5_user_path(license_without_owner.account_id, license_without_owner.id),
              },
            },
          ).and(
            exclude(
              owner: anything,
            ),
          ),
        ),
        include(
          relationships: include(
            user: {
              data: { type: :users, id: license_with_owner.owner_id },
              links: {
                related: v1_account_license_v1_5_user_path(license_with_owner.account_id, license_with_owner.id),
              },
            },
          ).and(
            exclude(
              owner: anything,
            ),
          ),
        ),
      ],
    )
  end
end
