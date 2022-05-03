# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameFilenameExtErrorCodeForReleaseMigration do
  before do
    Versionist.configure do |config|
      config.current_version = '1.0'
      config.versions        = {
        '1.0' => [RenameFilenameExtErrorCodeForReleaseMigration],
      }
    end
  end

  context 'the errors contain a ARTIFACT_FILENAME_EXTENSION_INVALID error code' do
    it 'should migrate the error' do
      migrator = Versionist::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unprocessable resource',
            detail: 'filename extension does not match filetype (expected exe)',
            code: 'ARTIFACT_FILENAME_EXTENSION_INVALID',
            source: {
              pointer: '/data/relationships/artifact/data/attributes/filename',
            },
            links: {
              about: 'https://keygen.sh/docs/api/releases/#releases-object-relationships-artifact',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            code: 'FILENAME_EXTENSION_INVALID',
            source: {
              pointer: '/data/attributes/filename',
            },
          ),
        ],
      )
    end
  end

  context 'the errors do not contain a ARTIFACT_FILENAME_EXTENSION_INVALID error code' do
    it 'should migrate the error' do
      migrator = Versionist::Migrator.new(from: '1.0', to: '1.0')
      data    = {
        errors: [
          {
            title: 'Unprocessable resource',
            detail: 'must be a valid version',
            code: 'VERSION_INVALID',
            source: {
              pointer: '/data/attributes/version',
            },
          },
        ],
      }

      migrator.migrate!(data:)

      expect(data).to include(
        errors: [
          include(
            code: 'VERSION_INVALID',
            source: {
              pointer: '/data/attributes/version',
            },
          ),
        ],
      )
    end
  end
end
