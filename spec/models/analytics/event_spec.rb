# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Event do
  let(:account) { create(:account) }

  describe '.new', :only_clickhouse do
    it 'returns event count' do
      event = described_class.new(
        'license.validation.succeeded',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(event).to be_a(Analytics::Event)
      expect(event).to be_valid
      expect(event.rows).to satisfy do
        it in [
          Analytics::Event::Row(event: 'license.validation.succeeded', count: Integer)
        ]
      end
    end

    it 'supports wildcard events' do
      event = described_class.new(
        'license.*',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(event).to be_a(Analytics::Event)
      expect(event).to be_valid
      expect(event.rows).to satisfy do |rows|
        rows.all? { it in Analytics::Event::Row(event: /\Alicense\./, count: Integer) }
      end
    end

    context 'with invalid pattern' do
      it 'is invalid for unknown event' do
        event = described_class.new('invalid.event', account:)

        expect(event).not_to be_valid
        expect(event.errors[:pattern]).to include('is invalid')
      end

      it 'is invalid for unknown wildcard' do
        event = described_class.new('invalid.*', account:)

        expect(event).not_to be_valid
        expect(event.errors[:pattern]).to include('is invalid')
      end
    end
  end
end
