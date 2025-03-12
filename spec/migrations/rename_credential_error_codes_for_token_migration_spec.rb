# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameCredentialErrorCodesForTokenMigration do
  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameCredentialErrorCodesForTokenMigration],
      }
    end
  end

  context 'the errors contain an EMAIL_REQUIRED error code' do
    it 'should migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unauthorized',
            detail: 'email is required',
            code: 'EMAIL_REQUIRED'
          },
          {
            title: 'Unprocessable resource',
            detail: 'must be a valid iso8601 timestamp',
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            detail: 'email and password must be valid',
            code: 'CREDENTIALS_INVALID',
          ),
          include(
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          ),
        ],
      )
    end
  end

  context 'the errors contain an EMAIL_INVALID error code' do
    it 'should migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unauthorized',
            detail: 'email must be valid',
            code: 'EMAIL_INVALID'
          },
          {
            title: 'Unprocessable resource',
            detail: 'must be a valid iso8601 timestamp',
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            detail: 'email and password must be valid',
            code: 'CREDENTIALS_INVALID',
          ),
          include(
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          ),
        ],
      )
    end
  end

  context 'the errors contain a PASSWORD_REQUIRED error code' do
    it 'should migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unauthorized',
            detail: 'password is required',
            code: 'PASSWORD_REQUIRED'
          },
          {
            title: 'Unprocessable resource',
            detail: 'must be a valid iso8601 timestamp',
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            detail: 'email and password must be valid',
            code: 'CREDENTIALS_INVALID',
          ),
          include(
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          ),
        ],
      )
    end
  end

  context 'the errors contain a PASSWORD_INVALID error code' do
    it 'should migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unauthorized',
            detail: 'password must be valid',
            code: 'PASSWORD_INVALID'
          },
          {
            title: 'Unprocessable resource',
            detail: 'must be a valid iso8601 timestamp',
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            detail: 'email and password must be valid',
            code: 'CREDENTIALS_INVALID',
          ),
          include(
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          ),
        ],
      )
    end
  end

  context 'the errors contain a PASSWORD_NOT_SUPPORTED error code' do
    it 'should migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unauthorized',
            detail: 'password is unsupported',
            code: 'PASSWORD_NOT_SUPPORTED'
          },
          {
            title: 'Unprocessable resource',
            detail: 'must be a valid iso8601 timestamp',
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            detail: 'email and password must be valid',
            code: 'CREDENTIALS_INVALID',
          ),
          include(
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          ),
        ],
      )
    end
  end

  context 'the errors do not contain any credential error codes' do
    it 'should not migrate the error' do
      migrator = RequestMigrations::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unprocessable resource',
            detail: 'must be a valid iso8601 timestamp',
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            code: 'EXPIRY_INVALID',
            source: {
              pointer: '/data/attributes/expiry',
            },
          ).and(
            exclude(
              detail: 'email and password must be valid',
              code: 'CREDENTIALS_INVALID',
            ),
          ),
        ],
      )
    end
  end
end
