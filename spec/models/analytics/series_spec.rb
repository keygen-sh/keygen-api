# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Series do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe ':events', :only_clickhouse do
    it 'returns event count timeseries' do
      series = described_class.new(
        :events,
        event_pattern: 'license.validation.succeeded',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to all(
        satisfy { it in Analytics::Series::Bucket(metric: 'license.validation.succeeded', date: Date, count: Integer) }
      )
      expect(series.buckets.size).to eq(8)
    end

    it 'supports wildcard patterns' do
      series = described_class.new(
        :events,
        event_pattern: 'license.*',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to all(
        satisfy { it in Analytics::Series::Bucket(metric: /\Alicense\./, date: Date, count: Integer) }
      )
    end

    it 'supports resource filtering' do
      license1 = create(:license, account:)
      license2 = create(:license, account:)

      create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license1)
      create_list(:event_log, 2, :license_validation_succeeded, account:, resource: license2)

      series = described_class.new(
        :events,
        event_pattern: 'license.validation.succeeded',
        account:,
        resource_type: 'License',
        resource_id: license1.id,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets.sum(&:count)).to eq(3)
      expect(series.buckets).to all(
        satisfy { it in Analytics::Series::Bucket(metric: 'license.validation.succeeded', date: Date, count: Integer) }
      )
    end

    context 'with invalid pattern' do
      it 'is invalid for unknown event' do
        series = described_class.new(:events, event_pattern: 'invalid.event', account:)

        expect(series).not_to be_valid
        expect(series.errors[:metrics]).to include('is invalid')
      end

      it 'is invalid for unknown wildcard' do
        series = described_class.new(:events, event_pattern: 'invalid.*', account:)

        expect(series).not_to be_valid
        expect(series.errors[:metrics]).to include('is invalid')
      end
    end
  end

  describe ':requests', :only_clickhouse do
    it 'returns request counts by date' do
      create_list(:request_log, 3, account:, created_at: 2.days.ago)
      create_list(:request_log, 2, account:, created_at: 1.day.ago)

      two_days_ago = 2.days.ago.to_date
      one_day_ago  = 1.day.ago.to_date

      series = described_class.new(
        :requests,
        account:,
        start_date: 3.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          *,
          Analytics::Series::Bucket(metric: 'requests', date: ^two_days_ago, count: 3),
          Analytics::Series::Bucket(metric: 'requests', date: ^one_day_ago, count: 2),
          *
        ]
      end
    end

    it 'includes zero counts for days with no requests' do
      create(:request_log, account:, created_at: 3.days.ago)

      three_days_ago = 3.days.ago.to_date
      two_days_ago   = 2.days.ago.to_date

      series = described_class.new(
        :requests,
        account:,
        start_date: 3.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'requests', date: ^three_days_ago, count: 1),
          Analytics::Series::Bucket(metric: 'requests', date: ^two_days_ago, count: 0),
          *
        ]
      end
    end
  end

  describe 'invalid series' do
    it 'raises for unknown counter' do
      expect { described_class.new(:invalid, account:) }.to raise_error(Analytics::SeriesNotFoundError)
    end
  end
end
