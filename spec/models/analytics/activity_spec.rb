# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Activity do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe '.new', :only_clickhouse do
    it 'returns activity count' do
      activity = described_class.new(
        'license.validation.succeeded',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(activity).to be_a(Analytics::Activity)
      expect(activity).to be_valid
      expect(activity.buckets).to satisfy do
        it in [
          Analytics::Activity::Bucket(event: 'license.validation.succeeded', count: Integer)
        ]
      end
    end

    it 'supports wildcard patterns' do
      activity = described_class.new(
        'license.*',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(activity).to be_a(Analytics::Activity)
      expect(activity).to be_valid
      expect(activity.buckets).to satisfy do |buckets|
        buckets.all? { it in Analytics::Activity::Bucket(event: /\Alicense\./, count: Integer) }
      end
    end

    it 'supports resource filtering' do
      license1 = create(:license, account:)
      license2 = create(:license, account:)

      create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license1)
      create_list(:event_log, 2, :license_validation_succeeded, account:, resource: license2)

      activity = described_class.new(
        'license.validation.succeeded',
        account:,
        resource_type: 'License',
        resource_id: license1.id,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(activity).to be_valid
      expect(activity.buckets).to eq [
        Analytics::Activity::Bucket.new(event: 'license.validation.succeeded', count: 3),
      ]
    end

    context 'with invalid pattern' do
      it 'is invalid for unknown event' do
        activity = described_class.new('invalid.event', account:)

        expect(activity).not_to be_valid
        expect(activity.errors[:pattern]).to include('is invalid')
      end

      it 'is invalid for unknown wildcard' do
        activity = described_class.new('invalid.*', account:)

        expect(activity).not_to be_valid
        expect(activity.errors[:pattern]).to include('is invalid')
      end
    end
  end
end
