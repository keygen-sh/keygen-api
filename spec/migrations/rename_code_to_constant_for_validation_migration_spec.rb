# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RenameCodeToConstantForValidationMigration do
  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.1'
      config.versions        = {
        '1.1' => [RenameCodeToConstantForValidationMigration],
      }
    end
  end

  it "should migrate a validation's code" do
    migrator = RequestMigrations::Migrator.new(from: '1.1', to: '1.1')
    data     = {
      meta: {
        detail: 'is valid',
        code: 'VALID',
        valid: true,
      },
    }

    migrator.migrate!(data:)

    expect(data).to include(
      meta: {
        detail: 'is valid',
        constant: 'VALID',
        valid: true,
      },
    )
  end
end
