# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordEventSparkWorker, :only_clickhouse do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should aggregate per-event type' do
    license = create(:license, account:)

    create_list(:event_log, 3, :license_created,                account:, resource: license)
    create_list(:event_log, 2, :license_validation_succeeded,   account:, resource: license, metadata: { code: 'VALID' })
    create_list(:event_log, 1, :machine_created,                account:, resource: create(:machine, account:, license:))

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = EventSpark.for_account(account)
                       .order(
                         created_at: :desc,
                       )

    license_created_id            = EventType.find_by(event: 'license.created').id
    license_validation_success_id = EventType.find_by(event: 'license.validation.succeeded').id
    machine_created_id            = EventType.find_by(event: 'machine.created').id

    expect(sparks).to satisfy do
      it in [
        EventSpark(event_type_id: ^machine_created_id,            count: 1),
        EventSpark(event_type_id: ^license_validation_success_id, count: 2),
        EventSpark(event_type_id: ^license_created_id,            count: 3),
      ]
    end
  end

  it 'should aggregate per-environment' do
    environment_a    = create(:environment, :shared, account:)
    environment_a_id = environment_a.id

    environment_b    = create(:environment, account:)
    environment_b_id = environment_b.id

    license_a = create(:license, account:, environment: environment_a)
    license_b = create(:license, account:, environment: environment_b)
    license_c = create(:license, account:, environment: nil)

    create_list(:event_log, 3, :license_created, account:, resource: license_a, environment: environment_a)
    create_list(:event_log, 2, :license_created, account:, resource: license_b, environment: environment_b)
    create_list(:event_log, 1, :license_created, account:, resource: license_c, environment: nil)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = EventSpark.for_account(account)
                       .order(
                         created_at: :desc,
                       )

    license_created_id = EventType.find_by(event: 'license.created').id

    expect(sparks).to satisfy do
      it in [
        EventSpark(environment_id: nil,               event_type_id: ^license_created_id, count: 1),
        EventSpark(environment_id: ^environment_b_id, event_type_id: ^license_created_id, count: 2),
        EventSpark(environment_id: ^environment_a_id, event_type_id: ^license_created_id, count: 3),
      ]
    end
  end

  it 'should not record sparks when there are no event logs' do
    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = EventSpark.for_account(account)

    expect(sparks.count).to eq(0)
  end

  it 'should not record sparks for other accounts' do
    other_account = create(:account)
    other_license = create(:license, account: other_account)

    license = create(:license, account:)

    create_list(:event_log, 3, :license_created, account: other_account, resource: other_license)
    create_list(:event_log, 2, :license_created, account:,               resource: license)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    other_sparks = EventSpark.for_account(other_account)

    expect(other_sparks.count).to eq(0)

    sparks = EventSpark.for_account(account)

    expect(sparks.count).to eq(1)
  end
end
