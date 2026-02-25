# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Leaderboard do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe '.new', :only_clickhouse do
    context 'with valid leaderboard' do
      it 'returns leaderboard for ips' do
        leaderboard = described_class.new(:ips, account:)

        expect(leaderboard).to be_a(Analytics::Leaderboard)
        expect(leaderboard).to be_valid
      end

      it 'returns leaderboard for urls' do
        leaderboard = described_class.new(:urls, account:)

        expect(leaderboard).to be_a(Analytics::Leaderboard)
        expect(leaderboard).to be_valid
      end

      it 'returns leaderboard for licenses' do
        leaderboard = described_class.new(:licenses, account:)

        expect(leaderboard).to be_a(Analytics::Leaderboard)
        expect(leaderboard).to be_valid
      end

      it 'returns leaderboard for user_agents' do
        leaderboard = described_class.new(:user_agents, account:)

        expect(leaderboard).to be_a(Analytics::Leaderboard)
        expect(leaderboard).to be_valid
      end

      it 'accepts string names' do
        leaderboard = described_class.new('ips', account:)

        expect(leaderboard).to be_a(Analytics::Leaderboard)
        expect(leaderboard).to be_valid
      end
    end

    context 'with invalid leaderboard' do
      it 'raises error' do
        expect { described_class.new(:invalid, account:) }.to raise_error(Analytics::LeaderboardNotFoundError)
      end
    end
  end

  describe 'ips', :only_clickhouse do
    context 'with no requests' do
      it 'returns empty array' do
        leaderboard = described_class.new(:ips, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to eq([])
      end
    end

    context 'with requests from different IPs' do
      before do
        3.times { create(:request_log, account:, ip: '192.168.1.1') }
        2.times { create(:request_log, account:, ip: '192.168.1.2') }
        1.times { create(:request_log, account:, ip: '192.168.1.3') }
      end

      it 'returns scores ordered by count descending' do
        leaderboard = described_class.new(:ips, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy do
          it in [
            Analytics::Leaderboard::Score(discriminator: '192.168.1.1', count: 3),
            Analytics::Leaderboard::Score(discriminator: '192.168.1.2', count: 2),
            Analytics::Leaderboard::Score(discriminator: '192.168.1.3', count: 1)
          ]
        end
      end
    end

    context 'with requests with nil or empty IPs' do
      before do
        create(:request_log, account:, ip: '192.168.1.1')
        create(:request_log, account:, ip: nil)
        create(:request_log, account:, ip: '')
      end

      it 'excludes nil and empty IPs' do
        leaderboard = described_class.new(:ips, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: '192.168.1.1', count: 1)] }
      end
    end

    context 'with date range filtering' do
      before do
        create(:request_log, account:, ip: '192.168.1.1', created_at: 3.days.ago)
        create(:request_log, account:, ip: '192.168.1.2', created_at: 10.days.ago)
      end

      it 'only includes requests within date range' do
        leaderboard = described_class.new(:ips, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: '192.168.1.1', count: 1)] }
      end
    end

    context 'with limit parameter' do
      before do
        5.times { create(:request_log, account:, ip: "192.168.1.#{it + 1}") }
      end

      it 'respects custom limit' do
        leaderboard = described_class.new(:ips, account:, start_date: 7.days.ago.to_date, end_date: Date.current, limit: 3)

        expect(leaderboard.scores.length).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create(:request_log, account:, environment:, ip: '192.168.1.1')
        create(:request_log, account:, environment: nil, ip: '192.168.1.2')
      end

      it 'filters by environment' do
        leaderboard = described_class.new(:ips, account:, environment:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: '192.168.1.1', count: 1)] }
      end
    end
  end

  describe 'licenses', :only_clickhouse do
    context 'with no requests' do
      it 'returns empty array' do
        leaderboard = described_class.new(:licenses, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to eq([])
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

      it 'returns scores ordered by count descending' do
        license1_id = license1.id
        license2_id = license2.id
        license3_id = license3.id

        leaderboard = described_class.new(:licenses, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy do
          it in [
            Analytics::Leaderboard::Score(discriminator: ^license1_id, count: 3),
            Analytics::Leaderboard::Score(discriminator: ^license2_id, count: 2),
            Analytics::Leaderboard::Score(discriminator: ^license3_id, count: 1),
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

        leaderboard = described_class.new(:licenses, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: ^license_id, count: 1)] }
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

        leaderboard = described_class.new(:licenses, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: ^license_id, count: 1)] }
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

        leaderboard = described_class.new(:licenses, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: ^license1_id, count: 1)] }
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
        leaderboard = described_class.new(:licenses, account:, start_date: 7.days.ago.to_date, end_date: Date.current, limit: 3)

        expect(leaderboard.scores.length).to eq(3)
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

        leaderboard = described_class.new(:licenses, account:, environment:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: ^license1_id, count: 1)] }
      end
    end
  end

  describe 'urls', :only_clickhouse do
    context 'with no requests' do
      it 'returns empty array' do
        leaderboard = described_class.new(:urls, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to eq([])
      end
    end

    context 'with requests to different URLs' do
      before do
        3.times { create(:request_log, account:, method: 'GET', url: '/v1/licenses') }
        2.times { create(:request_log, account:, method: 'POST', url: '/v1/licenses') }
        1.times { create(:request_log, account:, method: 'GET', url: '/v1/machines') }
      end

      it 'returns scores ordered by count descending' do
        leaderboard = described_class.new(:urls, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy do
          it in [
            Analytics::Leaderboard::Score(discriminator: 'GET /v1/licenses', count: 3),
            Analytics::Leaderboard::Score(discriminator: 'POST /v1/licenses', count: 2),
            Analytics::Leaderboard::Score(discriminator: 'GET /v1/machines', count: 1)
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
        leaderboard = described_class.new(:urls, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: 'GET /v1/licenses', count: 1)] }
      end
    end

    context 'with date range filtering' do
      before do
        create(:request_log, account:, method: 'GET', url: '/v1/licenses', created_at: 3.days.ago)
        create(:request_log, account:, method: 'GET', url: '/v1/machines', created_at: 10.days.ago)
      end

      it 'only includes requests within date range' do
        leaderboard = described_class.new(:urls, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: 'GET /v1/licenses', count: 1)] }
      end
    end

    context 'with limit parameter' do
      before do
        5.times { create(:request_log, account:, method: 'GET', url: "/v1/resource#{it + 1}") }
      end

      it 'respects custom limit' do
        leaderboard = described_class.new(:urls, account:, start_date: 7.days.ago.to_date, end_date: Date.current, limit: 3)

        expect(leaderboard.scores.length).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create(:request_log, account:, environment:, method: 'GET', url: '/v1/licenses')
        create(:request_log, account:, environment: nil, method: 'GET', url: '/v1/machines')
      end

      it 'filters by environment' do
        leaderboard = described_class.new(:urls, account:, environment:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: 'GET /v1/licenses', count: 1)] }
      end
    end
  end

  describe 'user_agents', :only_clickhouse do
    context 'with no requests' do
      it 'returns empty array' do
        leaderboard = described_class.new(:user_agents, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to eq([])
      end
    end

    context 'with requests from different user agents' do
      before do
        3.times { create(:request_log, account:, user_agent: 'Mozilla/5.0 Chrome/120.0') }
        2.times { create(:request_log, account:, user_agent: 'curl/8.1.2') }
        1.times { create(:request_log, account:, user_agent: 'keygen/1.0.0') }
      end

      it 'returns scores ordered by count descending' do
        leaderboard = described_class.new(:user_agents, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy do
          it in [
            Analytics::Leaderboard::Score(discriminator: 'Mozilla/5.0 Chrome/120.0', count: 3),
            Analytics::Leaderboard::Score(discriminator: 'curl/8.1.2', count: 2),
            Analytics::Leaderboard::Score(discriminator: 'keygen/1.0.0', count: 1)
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
        leaderboard = described_class.new(:user_agents, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: 'curl/8.1.2', count: 1)] }
      end
    end

    context 'with date range filtering' do
      before do
        create(:request_log, account:, user_agent: 'curl/8.1.2', created_at: 3.days.ago)
        create(:request_log, account:, user_agent: 'keygen/1.0.0', created_at: 10.days.ago)
      end

      it 'only includes requests within date range' do
        leaderboard = described_class.new(:user_agents, account:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: 'curl/8.1.2', count: 1)] }
      end
    end

    context 'with limit parameter' do
      before do
        5.times { create(:request_log, account:, user_agent: "agent/#{it + 1}.0") }
      end

      it 'respects custom limit' do
        leaderboard = described_class.new(:user_agents, account:, start_date: 7.days.ago.to_date, end_date: Date.current, limit: 3)

        expect(leaderboard.scores.length).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create(:request_log, account:, environment:, user_agent: 'curl/8.1.2')
        create(:request_log, account:, environment: nil, user_agent: 'keygen/1.0.0')
      end

      it 'filters by environment' do
        leaderboard = described_class.new(:user_agents, account:, environment:, start_date: 7.days.ago.to_date, end_date: Date.current)

        expect(leaderboard.scores).to satisfy { it in [Analytics::Leaderboard::Score(discriminator: 'curl/8.1.2', count: 1)] }
      end
    end
  end
end
