# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameOwnerRelationshipToUserForMachinesMigration do
  let(:account)               { create(:account) }
  let(:license_without_owner) { create(:license, :without_owner, account:) }
  let(:license_with_owner)    { create(:license, :with_owner, account:) }
  let(:machine_without_owner) { create(:machine, license: license_without_owner, account:) }
  let(:machine_with_owner)    { create(:machine, license: license_with_owner, account:) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = CURRENT_API_VERSION
      config.versions        = {
        '1.0' => [RenameOwnerRelationshipToUserForMachinesMigration],
      }
    end
  end

  it 'should migrate machine owner relationships' do
    migrator = RequestMigrations::Migrator.new(from: CURRENT_API_VERSION, to: '1.0')
    data     = Keygen::JSONAPI.render(
      [
        machine_without_owner,
        machine_with_owner,
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
                related: v1_account_machine_owner_path(machine_without_owner.account_id, machine_without_owner.id),
              },
            },
          ),
        ),
        include(
          relationships: include(
            owner: {
              data: { type: :users, id: machine_with_owner.owner.id },
              links: {
                related: v1_account_machine_owner_path(machine_with_owner.account_id, machine_with_owner.id),
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
                related: v1_account_machine_v1_5_user_path(machine_without_owner.account_id, machine_without_owner.id),
              },
            },
          ),
        ),
        include(
          relationships: include(
            user: {
              data: { type: :users, id: machine_with_owner.owner.id },
              links: {
                related: v1_account_machine_v1_5_user_path(machine_with_owner.account_id, machine_with_owner.id),
              },
            },
          ),
        ),
      ],
    )
  end
end
