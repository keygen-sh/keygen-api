# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::ExpirationsHeatmapQuery do
  let(:account) { create(:account) }

  describe '.call' do
    context 'with no expiring licenses' do
      it 'returns cells with temperature 0' do
        results = described_class.call(
          account:,
          start_date: Date.current,
          end_date: 7.days.from_now.to_date,
        )

        expect(results).to be_an(Array)
        expect(results.length).to eq(8)
        expect(results).to all be_a(Analytics::Heatmap::Cell)
        expect(results).to all have_attributes(temperature: 0.0, count: 0)
      end
    end

    context 'with expiring licenses' do
      before do
        create(:license, account:, expiry: 3.days.from_now)
        create(:license, account:, expiry: 3.days.from_now)
        create(:license, account:, expiry: 5.days.from_now)
      end

      it 'returns cells with correct counts' do
        results = described_class.call(
          account:,
          start_date: Date.current,
          end_date: 7.days.from_now.to_date,
        )

        expiry_date_3 = 3.days.from_now.to_date
        expiry_date_5 = 5.days.from_now.to_date

        date_3_result = results.find { it.date == expiry_date_3 }
        date_5_result = results.find { it.date == expiry_date_5 }

        expect(date_3_result.count).to eq(2)
        expect(date_5_result.count).to eq(1)
      end

      it 'assigns correct temperature based on count distribution' do
        results = described_class.call(
          account:,
          start_date: Date.current,
          end_date: 7.days.from_now.to_date,
        )

        expiry_date_3 = 3.days.from_now.to_date
        date_3_result = results.find { it.date == expiry_date_3 }

        expect(date_3_result.temperature).to eq(1.0)
      end
    end

    context 'with default date range' do
      it 'uses today to 364 days from now' do
        results = described_class.call(account:)

        expect(results.first.date).to eq(Date.current)
        expect(results.last.date).to eq(364.days.from_now.to_date)
      end
    end
  end
end
