# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::IpsLeaderboardQuery do
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

    context 'with requests from different IPs' do
      before do
        3.times { create(:request_log, account:, ip: '192.168.1.1') }
        2.times { create(:request_log, account:, ip: '192.168.1.2') }
        1.times { create(:request_log, account:, ip: '192.168.1.3') }
      end

      it 'returns entries ordered by count descending' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to all be_a(Analytics::Leaderboard::Entry)
        expect(results.length).to eq(3)
        expect(results[0]).to have_attributes(identifier: '192.168.1.1', count: 3)
        expect(results[1]).to have_attributes(identifier: '192.168.1.2', count: 2)
        expect(results[2]).to have_attributes(identifier: '192.168.1.3', count: 1)
      end
    end

    context 'with requests with nil or empty IPs' do
      before do
        create(:request_log, account:, ip: '192.168.1.1')
        create(:request_log, account:, ip: nil)
        create(:request_log, account:, ip: '')
      end

      it 'excludes nil and empty IPs' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results.length).to eq(1)
        expect(results[0].identifier).to eq('192.168.1.1')
      end
    end

    context 'with date range filtering' do
      before do
        create(:request_log, account:, ip: '192.168.1.1', created_at: 3.days.ago)
        create(:request_log, account:, ip: '192.168.1.2', created_at: 10.days.ago)
      end

      it 'only includes requests within date range' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results.length).to eq(1)
        expect(results[0].identifier).to eq('192.168.1.1')
      end
    end

    context 'with limit parameter' do
      before do
        5.times { |i| create(:request_log, account:, ip: "192.168.1.#{i + 1}") }
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

      it 'enforces max limit of 100' do
        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
          limit: 200,
        )

        expect(results.length).to be <= 100
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create(:request_log, account:, environment:, ip: '192.168.1.1')
        create(:request_log, account:, environment: nil, ip: '192.168.1.2')
      end

      it 'filters by environment' do
        results = described_class.call(
          account:,
          environment:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results.length).to eq(1)
        expect(results[0].identifier).to eq('192.168.1.1')
      end
    end
  end
end
