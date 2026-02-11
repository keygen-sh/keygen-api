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

        expect(result).to be_a(Analytics::Event::Count)
        expect(result.event).to eq('license.validation.succeeded')
        expect(result.value).to be_an(Integer)
      end

      it 'supports wildcard events' do
        result = described_class.call(
          'license.*',
          account:,
          start_date: 7.days.ago.to_date,
          end_date: Date.current,
        )

        expect(result).to be_a(Analytics::Event::Count)
        expect(result.event).to eq('license.*')
        expect(result.value).to be_an(Integer)
      end
    end
  end
end
