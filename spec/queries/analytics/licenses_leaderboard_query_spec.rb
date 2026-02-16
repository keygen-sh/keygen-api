# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::LicensesLeaderboardQuery do
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

    context 'with requests for different licenses' do
      let(:license1) { create(:license, account:) }
      let(:license2) { create(:license, account:) }
      let(:license3) { create(:license, account:) }

      before do
        3.times { create(:request_log, account:, resource: license1) }
        2.times { create(:request_log, account:, resource: license2) }
        1.times { create(:request_log, account:, resource: license3) }
      end

      it 'returns entries ordered by count descending' do
        license1_id = license1.id
        license2_id = license2.id
        license3_id = license3.id

        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy do
          it in [
            Analytics::Leaderboard::Entry(identifier: ^license1_id, count: 3),
            Analytics::Leaderboard::Entry(identifier: ^license2_id, count: 2),
            Analytics::Leaderboard::Entry(identifier: ^license3_id, count: 1),
          ]
        end
      end
    end

    context 'with requests for non-license resources' do
      let(:license) { create(:license, account:) }
      let(:machine) { create(:machine, account:) }

      before do
        create(:request_log, account:, resource: license)
        create(:request_log, account:, resource: machine)
      end

      it 'only includes license resources' do
        license_id = license.id

        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy { it in [Analytics::Leaderboard::Entry(identifier: ^license_id, count: 1)] }
      end
    end

    context 'with requests with nil resource' do
      let(:license) { create(:license, account:) }

      before do
        create(:request_log, account:, resource: license)
        create(:request_log, account:, resource: nil)
      end

      it 'excludes nil resources' do
        license_id = license.id

        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy { it in [Analytics::Leaderboard::Entry(identifier: ^license_id, count: 1)] }
      end
    end

    context 'with date range filtering' do
      let(:license1) { create(:license, account:) }
      let(:license2) { create(:license, account:) }

      before do
        create(:request_log, account:, resource: license1, created_at: 3.days.ago)
        create(:request_log, account:, resource: license2, created_at: 10.days.ago)
      end

      it 'only includes requests within date range' do
        license1_id = license1.id

        results = described_class.call(
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy { it in [Analytics::Leaderboard::Entry(identifier: ^license1_id, count: 1)] }
      end
    end

    context 'with limit parameter' do
      before do
        5.times do
          license = create(:license, account:)
          create(:request_log, account:, resource: license)
        end
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
      let(:license1) { create(:license, account:, environment:) }
      let(:license2) { create(:license, account:, environment: nil) }

      before do
        create(:request_log, account:, environment:, resource: license1)
        create(:request_log, account:, environment: nil, resource: license2)
      end

      it 'filters by environment' do
        license1_id = license1.id

        results = described_class.call(
          account:,
          environment:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(results).to satisfy { it in [Analytics::Leaderboard::Entry(identifier: ^license1_id, count: 1)] }
      end
    end
  end
end
