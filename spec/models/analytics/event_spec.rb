# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Event do
  let(:account) { create(:account) }

  describe '.call' do
    context 'when ClickHouse is available', :clickhouse do
      before do
        skip 'ClickHouse is not available' unless Keygen.database.clickhouse_available?
      end

      it 'returns event count' do
        result = described_class.call(
          'license.validation.succeeded',
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(result).to satisfy do
          it in [
            Analytics::Event::Count(event: 'license.validation.succeeded', count: Integer)
          ]
        end
      end

      it 'supports wildcard events' do
        result = described_class.call(
          'license.*',
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(result).to satisfy do |counts|
          counts.all? { it in Analytics::Event::Count(event: /\Alicense\./, count: Integer) }
        end
      end
    end
  end
end
