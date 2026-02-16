# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Activity do
  let(:account) { create(:account) }

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
      expect(activity.rows).to satisfy do
        it in [
          Analytics::Activity::Row(event: 'license.validation.succeeded', count: Integer)
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
      expect(activity.rows).to satisfy do |rows|
        rows.all? { it in Analytics::Activity::Row(event: /\Alicense\./, count: Integer) }
      end
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
