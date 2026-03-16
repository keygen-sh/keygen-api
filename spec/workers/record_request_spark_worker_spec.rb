# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordRequestSparkWorker, :only_clickhouse do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should aggregate per-status' do
    create_list(:request_log, 3, account:, status: 200)
    create_list(:request_log, 2, account:, status: 201)
    create_list(:request_log, 1, account:, status: 404)
    create_list(:request_log, 2, account:, status: 500)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = RequestSpark.for_account(account)
                         .order(
                           created_at: :desc,
                         )

    expect(sparks).to satisfy do
      it in [
        RequestSpark(status: 500, count: 2),
        RequestSpark(status: 404, count: 1),
        RequestSpark(status: 201, count: 2),
        RequestSpark(status: 200, count: 3),
      ]
    end
  end

  it 'should aggregate per-environment' do
    environment_a    = create(:environment, :shared, account:)
    environment_a_id = environment_a.id

    environment_b    = create(:environment, account:)
    environment_b_id = environment_b.id

    create_list(:request_log, 1, account:, environment: nil,           status: 200)
    create_list(:request_log, 2, account:, environment: environment_b, status: 200)
    create_list(:request_log, 3, account:, environment: environment_a, status: 200)
    create_list(:request_log, 1, account:, environment: environment_a, status: 422)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = RequestSpark.for_account(account)
                         .order(
                           created_at: :desc,
                         )

    expect(sparks).to satisfy do
      it in [
        RequestSpark(environment_id: ^environment_a_id, status: 422, count: 1),
        RequestSpark(environment_id: ^environment_a_id, status: 200, count: 3),
        RequestSpark(environment_id: ^environment_b_id, status: 200, count: 2),
        RequestSpark(environment_id: nil,               status: 200, count: 1),
      ]
    end
  end

  it 'should not record sparks when there are no request logs' do
    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    sparks = RequestSpark.for_account(account)

    expect(sparks.count).to eq(0)
  end

  it 'should not record sparks for other accounts' do
    other_account = create(:account)

    create_list(:request_log, 3, account: other_account, status: 200)
    create_list(:request_log, 2, account:,               status: 200)

    travel_to 1.day.from_now do
      described_class.perform_async(account.id)
    end

    other_sparks = RequestSpark.for_account(other_account)

    expect(other_sparks.count).to eq(0)

    sparks = RequestSpark.for_account(account)

    expect(sparks.count).to eq(1)
  end
end
