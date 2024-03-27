# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameOwnerNotFoundErrorCodeForLicenseMigration do
  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameOwnerNotFoundErrorCodeForLicenseMigration],
      }
    end
  end

  context 'the errors contain an OWNER_NOT_FOUND error code' do
    it 'should migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unprocessable resource',
            detail: 'must exist',
            code: 'OWNER_NOT_FOUND',
            source: {
              pointer: '/data/relationships/owner',
            },
            links: {
              about: 'https://keygen.sh/docs/api/licenses/#licenses-object-relationships-owner',
            },
          },
          {
            title: 'Unprocessable resource',
            detail: 'is invalid',
            code: 'KEY_INVALID',
            source: {
              pointer: '/data/attributes/key',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            code: 'USER_NOT_FOUND',
            source: {
              pointer: '/data/relationships/user',
            },
          ),
          include(
            code: 'KEY_INVALID',
            source: {
              pointer: '/data/attributes/key',
            },
          ),
        ],
      )
    end
  end

  context 'the errors do not contain an OWNER_NOT_FOUND error code' do
    it 'should not migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unprocessable resource',
            detail: 'is invalid',
            code: 'KEY_INVALID',
            source: {
              pointer: '/data/attributes/key',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            code: 'KEY_INVALID',
            source: {
              pointer: '/data/attributes/key',
            },
          ),
        ],
      )
    end
  end
end
