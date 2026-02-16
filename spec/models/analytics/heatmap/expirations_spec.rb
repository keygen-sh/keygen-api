# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Heatmap::Expirations do
  let(:account) { create(:account) }

  describe '#result' do
    context 'with no expiring licenses' do
      it 'returns cells with temperature 0' do
        start_date = Date.current
        end_date   = 7.days.from_now.to_date

        results = described_class.new(account:, start_date:, end_date:).result

        expect(results.length).to eq(8)
        expect(results).to satisfy do
          it in [
            Analytics::Heatmap::Expirations::Result(date: ^start_date, temperature: 0.0, count: 0),
            *,
            Analytics::Heatmap::Expirations::Result(date: ^end_date, temperature: 0.0, count: 0)
          ]
        end
      end
    end

    context 'with expiring licenses' do
      before do
        create(:license, account:, expiry: 3.days.from_now)
        create(:license, account:, expiry: 3.days.from_now)
        create(:license, account:, expiry: 5.days.from_now)
      end

      it 'returns cells with correct counts' do
        start_date           = Date.current
        date_1_day_from_now  = 1.day.from_now.to_date
        date_2_days_from_now = 2.days.from_now.to_date
        date_3_days_from_now = 3.days.from_now.to_date
        date_4_days_from_now = 4.days.from_now.to_date
        date_5_days_from_now = 5.days.from_now.to_date
        end_date             = 6.days.from_now.to_date

        results = described_class.new(
          account:,
          start_date:,
          end_date:,
        ).result

        expect(results).to satisfy do
          it in [
            Analytics::Heatmap::Expirations::Result(date: ^start_date, count: 0),
            Analytics::Heatmap::Expirations::Result(date: ^date_1_day_from_now, count: 0),
            Analytics::Heatmap::Expirations::Result(date: ^date_2_days_from_now, count: 0),
            Analytics::Heatmap::Expirations::Result(date: ^date_3_days_from_now, count: 2),
            Analytics::Heatmap::Expirations::Result(date: ^date_4_days_from_now, count: 0),
            Analytics::Heatmap::Expirations::Result(date: ^date_5_days_from_now, count: 1),
            Analytics::Heatmap::Expirations::Result(date: ^end_date, count: 0)
          ]
        end
      end

      it 'assigns correct temperature based on count distribution' do
        mid_date = 3.days.from_now.to_date

        results = described_class.new(
          account:,
          start_date: Date.current,
          end_date: 7.days.from_now.to_date,
        ).result

        expect(results).to satisfy do
          it in [
            *,
            Analytics::Heatmap::Expirations::Result(date: ^mid_date, temperature: 1.0),
            *
          ]
        end
      end
    end

    context 'with default date range' do
      it 'uses today to 364 days from now' do
        start_date = Date.current
        end_date   = 364.days.from_now.to_date

        results = described_class.new(account:).result

        expect(results).to satisfy do
          it in [
            Analytics::Heatmap::Expirations::Result(date: ^start_date),
            *,
            Analytics::Heatmap::Expirations::Result(date: ^end_date)
          ]
        end
      end
    end
  end
end
