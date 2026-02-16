# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::UserAgentsLeaderboardQuery do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe '.call', :only_clickhouse do
    context 'with no requests' do
      it 'returns empty array' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to eq([])
      end
    end

    context 'with requests from different user agents' do
      before do
        3.times { create(:request_log, account:, user_agent: 'Mozilla/5.0 Chrome/120.0') }
        2.times { create(:request_log, account:, user_agent: 'curl/8.1.2') }
        1.times { create(:request_log, account:, user_agent: 'keygen/1.0.0') }
      end

      it 'returns entries ordered by count descending' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy do
          it in [
            Analytics::UserAgentsLeaderboardQuery::Result(identifier: 'Mozilla/5.0 Chrome/120.0', count: 3),
            Analytics::UserAgentsLeaderboardQuery::Result(identifier: 'curl/8.1.2', count: 2),
            Analytics::UserAgentsLeaderboardQuery::Result(identifier: 'keygen/1.0.0', count: 1)
          ]
        end
      end
    end

    context 'with requests with nil or empty user agents' do
      before do
        create(:request_log, account:, user_agent: 'curl/8.1.2')
        create(:request_log, account:, user_agent: nil)
        create(:request_log, account:, user_agent: '')
      end

      it 'excludes nil and empty user agents' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy { it in [Analytics::UserAgentsLeaderboardQuery::Result(identifier: 'curl/8.1.2', count: 1)] }
      end
    end

    context 'with date range filtering' do
      before do
        create(:request_log, account:, user_agent: 'curl/8.1.2', created_at: 3.days.ago)
        create(:request_log, account:, user_agent: 'keygen/1.0.0', created_at: 10.days.ago)
      end

      it 'only includes requests within date range' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy { it in [Analytics::UserAgentsLeaderboardQuery::Result(identifier: 'curl/8.1.2', count: 1)] }
      end
    end

    context 'with limit parameter' do
      before do
        5.times { create(:request_log, account:, user_agent: "agent/#{it + 1}.0") }
      end

      it 'respects custom limit' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
          limit: 3,
        )

        expect(results.length).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create(:request_log, account:, environment:, user_agent: 'curl/8.1.2')
        create(:request_log, account:, environment: nil, user_agent: 'keygen/1.0.0')
      end

      it 'filters by environment' do
        results = described_class.call(
          account:,
          environment:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy { it in [Analytics::UserAgentsLeaderboardQuery::Result(identifier: 'curl/8.1.2', count: 1)] }
      end
    end
  end
end
