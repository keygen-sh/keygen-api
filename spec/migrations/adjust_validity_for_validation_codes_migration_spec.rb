# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: %w[permissions event_types] }

describe AdjustValidityForValidationCodesMigration do
  before do
    Sidekiq::Testing.fake!
    StripeHelper.start
  end

  after do
    DatabaseCleaner.clean
    StripeHelper.stop
  end

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.1'
      config.versions        = {
        '1.1' => [AdjustValidityForValidationCodesMigration],
      }
    end
  end

  context 'code is VALID' do
    it "should not migrate validity" do
      migrator = RequestMigrations::Migrator.new(from: '1.1', to: '1.1')
      data     = {
        meta: {
          code: 'VALID',
          valid: true,
        },
      }

      migrator.migrate!(data:)

      expect(data).to include(
        meta: include(
          code: 'VALID',
          valid: true,
        ),
      )
    end
  end

  context 'code is EXPIRED' do
    it "should not migrate validity" do
      migrator = RequestMigrations::Migrator.new(from: '1.1', to: '1.1')
      data     = {
        meta: {
          code: 'EXPIRED',
          valid: true,
        },
      }

      migrator.migrate!(data:)

      expect(data).to include(
        meta: include(
          code: 'EXPIRED',
          valid: true,
        ),
      )
    end
  end

  %w[
    FINGERPRINT_SCOPE_MISMATCH
    NO_MACHINES
    NO_MACHINE
    TOO_MANY_MACHINES
    TOO_MANY_CORES
    TOO_MANY_PROCESSES
  ].each do |code|
    context "code is #{code}" do
    it "should migrate validity" do
      migrator = RequestMigrations::Migrator.new(from: '1.1', to: '1.1')
      data     = {
        meta: { valid: true, code: },
      }

      migrator.migrate!(data:)

      expect(data).to include(
        meta: include(valid: false, code:),
      )
    end
  end
  end
end
