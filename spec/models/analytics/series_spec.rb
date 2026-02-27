# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Series, :only_clickhouse do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe ':events' do
    it 'returns event count timeseries' do
      series = described_class.new(
        :events,
        event: 'license.validation.succeeded',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to all(
        satisfy { it in Analytics::Series::Bucket(metric: 'license.validation.succeeded', date: Date, count: Integer) }
      )
    end

    it 'supports wildcard patterns' do
      series = described_class.new(
        :events,
        event: 'license.*',
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
        event: 'license.validation.succeeded',
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
        series = described_class.new(:events, event: 'invalid.event', account:)

        expect(series).not_to be_valid
        expect(series.errors[:metrics]).to include('is invalid')
      end

      it 'is invalid for unknown wildcard' do
        series = described_class.new(:events, event: 'invalid.*', account:)

        expect(series).not_to be_valid
        expect(series.errors[:metrics]).to include('is invalid')
      end
    end
  end

  describe ':requests' do
    it 'returns request counts grouped by status bucket' do
      create_list(:request_log, 3, account:, status: '200', created_at: 2.days.ago)
      create_list(:request_log, 2, account:, status: '404', created_at: 2.days.ago)
      create_list(:request_log, 1, account:, status: '301', created_at: 1.day.ago)
      create_list(:request_log, 2, account:, status: '500', created_at: 1.day.ago)

      three_days_ago = 3.days.ago.to_date
      two_days_ago   = 2.days.ago.to_date
      one_day_ago    = 1.day.ago.to_date
      today          = Date.current

      series = described_class.new(
        :requests,
        account:,
        start_date: three_days_ago,
        end_date: today,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'requests.2xx', date: ^two_days_ago, count: 3),
          Analytics::Series::Bucket(metric: 'requests.3xx', date: ^one_day_ago, count: 1),
          Analytics::Series::Bucket(metric: 'requests.4xx', date: ^two_days_ago, count: 2),
          Analytics::Series::Bucket(metric: 'requests.5xx', date: ^one_day_ago, count: 2),
        ]
      end
    end

    it 'omits zero counts for days with no requests' do
      create(:request_log, account:, status: '200', created_at: 3.days.ago)

      three_days_ago = 3.days.ago.to_date

      series = described_class.new(
        :requests,
        account:,
        start_date: three_days_ago,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'requests.2xx', date: ^three_days_ago, count: 1),
        ]
      end
    end
  end

  describe ':sparks' do
    it 'returns a spark timeseries with realtime count for today' do
      three_days_ago = 3.days.ago.to_date
      two_days_ago   = 2.days.ago.to_date
      one_day_ago    = 1.day.ago.to_date
      today          = Date.current

      LicenseSpark.insert_all!([
        { account_id: account.id, environment_id: nil, count: 10, created_date: two_days_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, count: 12, created_date: one_day_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, count: 12, created_date: today, created_at: Time.current },
      ])

      create_list(:license, 15, account:)

      series = described_class.new(
        :sparks,
        metric: 'licenses',
        account:,
        start_date: three_days_ago,
        end_date: today,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: :licenses, date: ^two_days_ago, count: 10),
          Analytics::Series::Bucket(metric: :licenses, date: ^one_day_ago, count: 12),
          Analytics::Series::Bucket(metric: :licenses, date: ^today, count: 15),
        ]
      end
    end

    it 'returns a spark timeseries without realtime count for today' do
      two_days_ago = 2.days.ago.to_date
      one_day_ago  = 1.day.ago.to_date
      today        = Date.current

      LicenseSpark.insert_all!([
        { account_id: account.id, environment_id: nil, count: 10, created_date: two_days_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, count: 12, created_date: one_day_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, count: 12, created_date: today, created_at: Time.current },
      ])

      create_list(:license, 15, account:)

      series = described_class.new(
        :sparks,
        metric: 'licenses',
        account:,
        start_date: 3.days.ago.to_date,
        end_date: today,
        realtime: false,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: :licenses, date: ^two_days_ago, count: 10),
          Analytics::Series::Bucket(metric: :licenses, date: ^one_day_ago, count: 12),
          Analytics::Series::Bucket(metric: :licenses, date: ^today, count: 12),
        ]
      end
    end

    it 'uses realtime count for today even with zero resources' do
      one_day_ago = 1.day.ago.to_date
      today       = Date.current

      MachineSpark.insert_all!([
        { account_id: account.id, environment_id: nil, count: 5, created_date: one_day_ago, created_at: Time.current },
      ])

      series = described_class.new(
        :sparks,
        metric: :machines,
        account:,
        start_date: one_day_ago,
        end_date: today,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: :machines, date: ^one_day_ago, count: 5),
        ]
      end
    end

    it 'overwrites stale clickhouse data for today with realtime count' do
      today = Date.current

      LicenseSpark.insert_all!([
        { account_id: account.id, environment_id: nil, count: 8, created_date: today, created_at: Time.current },
      ])

      create_list(:license, 12, account:)

      series = described_class.new(
        :sparks,
        metric: 'licenses',
        account:,
        start_date: today,
        end_date: today,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: :licenses, date: ^today, count: 12),
        ]
      end
    end

    it 'does not use realtime count when end_date is before today' do
      three_days_ago = 3.days.ago.to_date
      one_day_ago    = 1.day.ago.to_date

      LicenseSpark.insert_all!([
        { account_id: account.id, environment_id: nil, count: 10, created_date: three_days_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, count: 12, created_date: one_day_ago, created_at: Time.current },
      ])

      create_list(:license, 20, account:)

      series = described_class.new(
        :sparks,
        metric: :licenses,
        account:,
        start_date: three_days_ago,
        end_date: one_day_ago,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: :licenses, date: ^three_days_ago, count: 10),
          Analytics::Series::Bucket(metric: :licenses, date: ^one_day_ago, count: 12),
        ]
      end
    end

    it 'is invalid for unknown spark' do
      series = described_class.new(:sparks, metric: :invalid, account:)

      expect(series).not_to be_valid
      expect(series.errors[:metrics]).to include('is invalid')
    end
  end

  describe ':validations' do
    it 'returns validation counts grouped by validation code' do
      license1 = create(:license, account:)
      license2 = create(:license, account:)

      two_days_ago = 2.days.ago.to_date
      one_day_ago  = 1.day.ago.to_date

      LicenseValidationSpark.insert_all!([
        { account_id: account.id, environment_id: nil, license_id: license1.id, validation_code: 'VALID',      count: 5, created_date: two_days_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, license_id: license2.id, validation_code: 'VALID',      count: 3, created_date: two_days_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, license_id: license1.id, validation_code: 'EXPIRED',    count: 2, created_date: one_day_ago,  created_at: Time.current },
        { account_id: account.id, environment_id: nil, license_id: license1.id, validation_code: 'NO_MACHINE', count: 3, created_date: one_day_ago,  created_at: Time.current },
      ])

      series = described_class.new(
        :validations,
        account:,
        start_date: 3.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to contain_exactly(
        satisfy { it in Analytics::Series::Bucket(metric: 'validations.valid',      date: ^two_days_ago, count: 8) },
        satisfy { it in Analytics::Series::Bucket(metric: 'validations.expired',    date: ^one_day_ago,  count: 2) },
        satisfy { it in Analytics::Series::Bucket(metric: 'validations.no-machine', date: ^one_day_ago,  count: 3) },
      )
    end

    it 'supports license filtering' do
      license1 = create(:license, account:)
      license2 = create(:license, account:)

      two_days_ago = 2.days.ago.to_date

      LicenseValidationSpark.insert_all!([
        { account_id: account.id, environment_id: nil, license_id: license1.id, validation_code: 'VALID', count: 5, created_date: two_days_ago, created_at: Time.current },
        { account_id: account.id, environment_id: nil, license_id: license2.id, validation_code: 'VALID', count: 3, created_date: two_days_ago, created_at: Time.current },
      ])

      series = described_class.new(
        :validations,
        account:,
        license_id: license1.id,
        start_date: 3.days.ago.to_date,
        end_date: Date.current,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'validations.valid', date: ^two_days_ago, count: 5),
        ]
      end
    end

    it 'returns empty buckets with no validation data' do
      series = described_class.new(:validations, account:)

      expect(series).to be_valid
      expect(series.buckets).to be_empty
    end

    it 'returns realtime counts for today from event log' do
      license = create(:license, account:)

      one_day_ago = 1.day.ago.to_date
      today       = Date.current

      LicenseValidationSpark.insert_all!([
        { account_id: account.id, environment_id: nil, license_id: license.id, validation_code: 'VALID', count: 5, created_date: one_day_ago, created_at: Time.current },
      ])

      create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license, metadata: { code: 'VALID' })
      create_list(:event_log, 2, :license_validation_failed,    account:, resource: license, metadata: { code: 'EXPIRED' })

      series = described_class.new(
        :validations,
        account:,
        start_date: one_day_ago,
        end_date: today,
      )

      expect(series).to be_valid
      expect(series.buckets).to contain_exactly(
        satisfy { it in Analytics::Series::Bucket(metric: 'validations.valid',   date: ^one_day_ago, count: 5) },
        satisfy { it in Analytics::Series::Bucket(metric: 'validations.valid',   date: ^today,       count: 3) },
        satisfy { it in Analytics::Series::Bucket(metric: 'validations.expired', date: ^today,       count: 2) },
      )
    end

    it 'overwrites stale spark data for today with realtime count' do
      license = create(:license, account:)

      today = Date.current

      LicenseValidationSpark.insert_all!([
        { account_id: account.id, environment_id: nil, license_id: license.id, validation_code: 'VALID', count: 2, created_date: today, created_at: Time.current },
      ])

      create_list(:event_log, 7, :license_validation_succeeded, account:, resource: license, metadata: { code: 'VALID' })

      series = described_class.new(
        :validations,
        account:,
        start_date: today,
        end_date: today,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'validations.valid', date: ^today, count: 7),
        ]
      end
    end

    it 'does not use realtime count when realtime is false' do
      license = create(:license, account:)

      today = Date.current

      LicenseValidationSpark.insert_all!([
        { account_id: account.id, environment_id: nil, license_id: license.id, validation_code: 'VALID', count: 2, created_date: today, created_at: Time.current },
      ])

      create_list(:event_log, 7, :license_validation_succeeded, account:, resource: license, metadata: { code: 'VALID' })

      series = described_class.new(
        :validations,
        account:,
        start_date: today,
        end_date: today,
        realtime: false,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'validations.valid', date: ^today, count: 2),
        ]
      end
    end

    it 'does not use realtime count when end_date is before today' do
      license = create(:license, account:)

      two_days_ago = 2.days.ago.to_date
      one_day_ago  = 1.day.ago.to_date

      LicenseValidationSpark.insert_all!([
        { account_id: account.id, environment_id: nil, license_id: license.id, validation_code: 'VALID', count: 5, created_date: two_days_ago, created_at: Time.current },
      ])

      create_list(:event_log, 10, :license_validation_succeeded, account:, resource: license, metadata: { code: 'VALID' })

      series = described_class.new(
        :validations,
        account:,
        start_date: two_days_ago,
        end_date: one_day_ago,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'validations.valid', date: ^two_days_ago, count: 5),
        ]
      end
    end

    it 'supports license filtering with realtime count' do
      license1 = create(:license, account:)
      license2 = create(:license, account:)

      today = Date.current

      create_list(:event_log, 5, :license_validation_succeeded, account:, resource: license1, metadata: { code: 'VALID' })
      create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license2, metadata: { code: 'VALID' })

      series = described_class.new(
        :validations,
        account:,
        license_id: license1.id,
        start_date: today,
        end_date: today,
      )

      expect(series).to be_valid
      expect(series.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Series::Bucket(metric: 'validations.valid', date: ^today, count: 5),
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
