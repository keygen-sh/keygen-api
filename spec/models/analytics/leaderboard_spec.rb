# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Leaderboard do
  let(:account) { create(:account) }

  describe '.call' do
    context 'when ClickHouse is available', :clickhouse do
      before do
        skip 'ClickHouse is not available' unless Keygen.database.clickhouse_available?
      end

      context 'with valid leaderboard' do
        it 'returns results for ips leaderboard' do
          results = described_class.call(:ips, account:)

          expect(results).to be_an(Array)
          expect(results).to all be_a(Analytics::Leaderboard::Entry)
        end

        it 'returns results for urls leaderboard' do
          results = described_class.call(:urls, account:)

          expect(results).to be_an(Array)
          expect(results).to all be_a(Analytics::Leaderboard::Entry)
        end

        it 'returns results for licenses leaderboard' do
          results = described_class.call(:licenses, account:)

          expect(results).to be_an(Array)
          expect(results).to all be_a(Analytics::Leaderboard::Entry)
        end

        it 'returns results for user_agents leaderboard' do
          results = described_class.call(:user_agents, account:)

          expect(results).to be_an(Array)
          expect(results).to all be_a(Analytics::Leaderboard::Entry)
        end

        it 'accepts string type names' do
          results = described_class.call('ips', account:)

          expect(results).to be_an(Array)
        end
      end

      context 'with invalid leaderboard' do
        it 'raises LeaderboardNotFoundError' do
          expect {
            described_class.call(:invalid, account:)
          }.to raise_error(Analytics::LeaderboardNotFoundError)
        end
      end
    end
  end
end
