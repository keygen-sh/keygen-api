# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Leaderboard::Urls do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe '#result', :only_clickhouse do
    context 'with no requests' do
      it 'returns empty array' do
        results = described_class.new(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        ).result

        expect(results).to eq([])
      end
    end

    context 'with requests to different URLs' do
      before do
        3.times { create(:request_log, account:, method: 'GET', url: '/v1/licenses') }
        2.times { create(:request_log, account:, method: 'POST', url: '/v1/licenses') }
        1.times { create(:request_log, account:, method: 'GET', url: '/v1/machines') }
      end

      it 'returns entries ordered by count descending' do
        results = described_class.new(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        ).result

        expect(results).to satisfy do
          it in [
            Analytics::Leaderboard::Base::Result(identifier: 'GET /v1/licenses', count: 3),
            Analytics::Leaderboard::Base::Result(identifier: 'POST /v1/licenses', count: 2),
            Analytics::Leaderboard::Base::Result(identifier: 'GET /v1/machines', count: 1)
          ]
        end
      end
    end

    context 'with requests with nil URL or method' do
      before do
        create(:request_log, account:, method: 'GET', url: '/v1/licenses')
        create(:request_log, account:, method: nil, url: '/v1/licenses')
        create(:request_log, account:, method: 'GET', url: nil)
      end

      it 'excludes nil URLs and methods' do
        results = described_class.new(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        ).result

        expect(results).to satisfy { it in [Analytics::Leaderboard::Base::Result(identifier: 'GET /v1/licenses', count: 1)] }
      end
    end

    context 'with date range filtering' do
      before do
        create(:request_log, account:, method: 'GET', url: '/v1/licenses', created_at: 3.days.ago)
        create(:request_log, account:, method: 'GET', url: '/v1/machines', created_at: 10.days.ago)
      end

      it 'only includes requests within date range' do
        results = described_class.new(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        ).result

        expect(results).to satisfy { it in [Analytics::Leaderboard::Base::Result(identifier: 'GET /v1/licenses', count: 1)] }
      end
    end

    context 'with limit parameter' do
      before do
        5.times { create(:request_log, account:, method: 'GET', url: "/v1/resource#{it + 1}") }
      end

      it 'respects custom limit' do
        results = described_class.new(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        ).result

        expect(results.length).to eq(5)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create(:request_log, account:, environment:, method: 'GET', url: '/v1/licenses')
        create(:request_log, account:, environment: nil, method: 'GET', url: '/v1/machines')
      end

      it 'filters by environment' do
        results = described_class.new(
          account:,
          environment:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        ).result

        expect(results).to satisfy { it in [Analytics::Leaderboard::Base::Result(identifier: 'GET /v1/licenses', count: 1)] }
      end
    end
  end
end
