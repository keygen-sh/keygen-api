# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Event do
  let(:account) { create(:account) }

  describe '.call', :only_clickhouse do
    it 'returns event count' do
      event = described_class.call(
        'license.validation.succeeded',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(event).to be_valid
      expect(event.result).to satisfy do
        it in [
          Analytics::Event::Result(event: 'license.validation.succeeded', count: Integer)
        ]
      end
    end

    it 'supports wildcard events' do
      event = described_class.call(
        'license.*',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(event).to be_valid
      expect(event.result).to satisfy do |counts|
        counts.all? { it in Analytics::Event::Result(event: /\Alicense\./, count: Integer) }
      end
    end

    context 'with invalid pattern' do
      it 'is invalid for unknown event' do
        event = described_class.call('invalid.event', account:)

        expect(event).not_to be_valid
        expect(event.errors[:pattern]).to include('is invalid')
      end

      it 'is invalid for unknown wildcard' do
        event = described_class.call('invalid.*', account:)

        expect(event).not_to be_valid
        expect(event.errors[:pattern]).to include('is invalid')
      end
    end
  end
end
