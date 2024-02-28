# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameOwnerRelationshipToUserForLicenseMigration do
  let(:account)               { create(:account) }
  let(:license_without_owner) { create(:license, :without_owner, account:) }
  let(:license_with_owner)    { create(:license, :with_owner, account:) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = CURRENT_API_VERSION
      config.versions        = {
        '1.0' => [RenameOwnerRelationshipToUserForLicenseMigration],
      }
    end
  end

  context 'when the license does not have an owner' do
    subject { license_without_owner }

    it 'should migrate a license owner relationship' do
      migrator = RequestMigrations::Migrator.new(from: CURRENT_API_VERSION, to: '1.0')
      data     = Keygen::JSONAPI.render(
        subject,
        api_version: CURRENT_API_VERSION,
        account:,
      )

      expect(data).to include(
        data: include(
          relationships: include(
            owner: {
              data: nil,
              links: {
                related: v1_account_license_owner_path(subject.account_id, subject.id),
              },
            },
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          relationships: include(
            user: {
              data: nil,
              links: {
                related: v1_account_license_v1_5_user_path(subject.account_id, subject.id),
              },
            },
          ),
        ),
      )
    end
  end

  context 'when the license has an owner' do
    subject { license_with_owner }

    it 'should migrate a license owner relationship' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data     = Keygen::JSONAPI.render(
        subject,
        api_version: CURRENT_API_VERSION,
        account:,
      )

      expect(data).to include(
        data: include(
          relationships: include(
            owner: {
              data: { type: :users, id: subject.owner_id },
              links: {
                related: v1_account_license_owner_path(subject.account_id, subject.id),
              },
            },
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          relationships: include(
            user: {
              data: { type: :users, id: subject.owner_id },
              links: {
                related: v1_account_license_v1_5_user_path(subject.account_id, subject.id),
              },
            },
          ),
        ),
      )
    end
  end
end
