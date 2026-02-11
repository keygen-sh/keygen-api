# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::EventCountQuery do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe '.call', :only_clickhouse do
    context 'with no events' do
      it 'returns zero count' do
        counts = described_class.call(
          account:,
          environment: nil,
          event: 'license.validation.succeeded',
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(counts).to satisfy { it in [Analytics::Event::Count(event: 'license.validation.succeeded', count: 0)] }
      end
    end

    context 'with wildcard event' do
      it 'returns counts for matching event types ordered by event name' do
        counts = described_class.call(
          account:,
          environment: nil,
          event: 'license.validation.*',
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(counts).to satisfy do
          it in [
            Analytics::Event::Count(event: 'license.validation.failed', count: Integer),
            Analytics::Event::Count(event: 'license.validation.succeeded', count: Integer),
          ]
        end
      end

      it 'returns entries for all matching event types' do
        counts = described_class.call(
          account:,
          environment: nil,
          event: 'license.*',
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        events = counts.map(&:event)
        expect(events).to all start_with('license.')
      end
    end

    context 'with events' do
      let(:event_type) { EventType.find_by!(event: 'license.validation.succeeded') }

      before do
        3.times { create(:event_log, account:, event_type:) }
      end

      it 'returns correct count for specific event' do
        counts = described_class.call(
          account:,
          environment: nil,
          event: 'license.validation.succeeded',
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(counts).to satisfy { it in [Analytics::Event::Count(event: 'license.validation.succeeded', count: 3)] }
      end
    end

    context 'with date range filtering' do
      let(:event_type) { EventType.find_by!(event: 'license.validation.succeeded') }

      before do
        create(:event_log, account:, event_type:, created_at: 3.days.ago)
        create(:event_log, account:, event_type:, created_at: 10.days.ago)
      end

      it 'only includes events within date range' do
        counts = described_class.call(
          account:,
          environment: nil,
          event: 'license.validation.succeeded',
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(counts).to satisfy { it in [Analytics::Event::Count(event: 'license.validation.succeeded', count: 1)] }
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }
      let(:event_type) { EventType.find_by!(event: 'license.validation.succeeded') }

      before do
        create(:event_log, account:, environment:, event_type:)
        create(:event_log, account:, environment: nil, event_type:)
      end

      it 'filters by environment' do
        counts = described_class.call(
          account:,
          environment:,
          event: 'license.validation.succeeded',
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(counts).to satisfy { it in [Analytics::Event::Count(event: 'license.validation.succeeded', count: 1)] }
      end
    end

    context 'with events from different accounts' do
      let(:other_account) { create(:account) }
      let(:event_type) { EventType.find_by!(event: 'license.validation.succeeded') }

      before do
        create(:event_log, account:, event_type:)
        create(:event_log, account: other_account, event_type:)
      end

      it 'only counts events for the specified account' do
        counts = described_class.call(
          account:,
          environment: nil,
          event: 'license.validation.succeeded',
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(counts).to satisfy { it in [Analytics::Event::Count(event: 'license.validation.succeeded', count: 1)] }
      end
    end
  end
end
