# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordLicenseValidationSparkWorker, :only_clickhouse do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should aggregate per-license and validation code' do
    license_a    = create(:license, account:)
    license_a_id = license_a.id

    license_b    = create(:license, account:)
    license_b_id = license_b.id

    create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license_a, metadata: { code: 'VALID' })
    create_list(:event_log, 2, :license_validation_failed,    account:, resource: license_a, metadata: { code: 'EXPIRED' })
    create_list(:event_log, 1, :license_validation_succeeded, account:, resource: license_b, metadata: { code: 'VALID' })
    create_list(:event_log, 1, :license_validation_failed,    account:, resource: license_b, metadata: { code: 'SUSPENDED' })

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = LicenseValidationSpark.for_account(account)
                                   .order(
                                     created_at: :desc,
                                   )

    expect(sparks).to satisfy do
      it in [
        LicenseValidationSpark(license_id: ^license_b_id, validation_code: 'SUSPENDED', count: 1),
        LicenseValidationSpark(license_id: ^license_b_id, validation_code: 'VALID',     count: 1),
        LicenseValidationSpark(license_id: ^license_a_id, validation_code: 'EXPIRED',   count: 2),
        LicenseValidationSpark(license_id: ^license_a_id, validation_code: 'VALID',     count: 3),
      ]
    end
  end

  it 'should aggregate per-environment' do
    environment_a    = create(:environment, :shared, account:)
    environment_a_id = environment_a.id
    license_a        = create(:license, account:, environment: environment_a)
    license_a_id     = license_a.id

    environment_b    = create(:environment, account:)
    environment_b_id = environment_b.id
    license_b        = create(:license, account:, environment: environment_b)
    license_b_id     = license_b.id

    license_c        = create(:license, account:, environment: nil)
    license_c_id     = license_c.id

    create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license_a, environment: environment_a, metadata: { code: 'VALID' })
    create_list(:event_log, 2, :license_validation_failed,    account:, resource: license_a, environment: environment_a, metadata: { code: 'FINGERPRINT_SCOPE_MISMATCH' })
    create_list(:event_log, 1, :license_validation_succeeded, account:, resource: license_b, environment: environment_b, metadata: { code: 'VALID' })
    create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license_c, environment: nil,           metadata: { code: 'VALID' })
    create_list(:event_log, 2, :license_validation_succeeded, account:, resource: license_c, environment: environment_a, metadata: { code: 'VALID' })
    create_list(:event_log, 1, :license_validation_failed,    account:, resource: license_c, environment: environment_a, metadata: { code: 'EXPIRED' })

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = LicenseValidationSpark.for_account(account)
                                   .order(
                                     created_at: :desc,
                                   )

    expect(sparks).to satisfy do
      it in [
        LicenseValidationSpark(license_id: ^license_c_id, environment_id: ^environment_a_id, validation_code: 'EXPIRED',                    count: 1),
        LicenseValidationSpark(license_id: ^license_c_id, environment_id: ^environment_a_id, validation_code: 'VALID',                      count: 2),
        LicenseValidationSpark(license_id: ^license_c_id, environment_id: nil,               validation_code: 'VALID',                      count: 3),
        LicenseValidationSpark(license_id: ^license_b_id, environment_id: ^environment_b_id, validation_code: 'VALID',                      count: 1),
        LicenseValidationSpark(license_id: ^license_a_id, environment_id: ^environment_a_id, validation_code: 'FINGERPRINT_SCOPE_MISMATCH', count: 2),
        LicenseValidationSpark(license_id: ^license_a_id, environment_id: ^environment_a_id, validation_code: 'VALID',                      count: 3),
      ]
    end
  end

  it 'should not record sparks when there are no validation events' do
    create(:license, account:)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = LicenseValidationSpark.for_account(account)

    expect(sparks.count).to eq(0)
  end

  it 'should not record sparks for non-validation events' do
    license = create(:license, account:)

    create_list(:event_log, 3, :license_created, account:, resource: license)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = LicenseValidationSpark.for_account(account)

    expect(sparks.count).to eq(0)
  end

  it 'should not record sparks for other accounts' do
    other_account = create(:account)
    other_license = create(:license, account: other_account)

    license = create(:license, account:)

    create_list(:event_log, 3, :license_validation_succeeded, account: other_account, resource: other_license, metadata: { code: 'VALID' })
    create_list(:event_log, 3, :license_validation_succeeded, account:,               resource: license,       metadata: { code: 'VALID' })

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    other_sparks = LicenseValidationSpark.for_account(other_account)

    expect(other_sparks.count).to eq(0)

    sparks = LicenseValidationSpark.for_account(account)

    expect(sparks.count).to eq(1)
  end
end
