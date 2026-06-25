# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Heatmap do
  let(:account) { create(:account) }

  describe '.new' do
    context 'with valid heatmap' do
      it 'returns heatmap for license expirations' do
        heatmap = described_class.new(:expirations, account:)

        expect(heatmap).to be_a(Analytics::Heatmap)
        expect(heatmap).to be_valid
      end

      it 'accepts string names' do
        heatmap = described_class.new('expirations', account:)

        expect(heatmap).to be_a(Analytics::Heatmap)
        expect(heatmap).to be_valid
      end

      it 'accepts date range' do
        start_date = Date.current
        end_date   = 30.days.from_now.to_date

        heatmap = described_class.new(
          :expirations,
          account:,
          start_date:,
          end_date:,
        )

        expect(heatmap).to be_a(Analytics::Heatmap)
        expect(heatmap).to be_valid
      end
    end

    context 'with invalid heatmap' do
      it 'raises error' do
        expect { described_class.new(:invalid, account:) }.to raise_error(Analytics::HeatmapNotFoundError)
      end
    end
  end

  describe 'expirations' do
    context 'with no expiring licenses' do
      it 'returns no cells' do
        heatmap = described_class.new(
          :expirations,
          account:,
          start_date: Date.current,
          end_date: 7.days.from_now.to_date,
        )

        expect(heatmap.cells).to be_empty
      end
    end

    context 'with expiring licenses' do
      before do
        create(:license, account:, expiry: 1.day.ago)
        create(:license, account:, expiry: 3.days.from_now)
        create(:license, account:, expiry: 3.days.from_now)
        create(:license, account:, expiry: 5.days.from_now)
        create(:license, account:, expiry: 7.days.from_now)
      end

      it 'returns cells with correct counts' do
        three_days_from_now = 3.days.from_now.to_date
        five_days_from_now  = 5.days.from_now.to_date

        heatmap = described_class.new(
          :expirations,
          account:,
          start_date: Date.current,
          end_date: 6.days.from_now.to_date,
        )

        expect(heatmap.cells).to satisfy do
          it in [
            Analytics::Heatmap::Cell(date: ^three_days_from_now, count: 2),
            Analytics::Heatmap::Cell(date: ^five_days_from_now, count: 1),
          ]
        end
      end

      it 'returns temperature based on count distribution' do
        mid_date = 3.days.from_now.to_date

        heatmap = described_class.new(
          :expirations,
          account:,
          start_date: Date.current,
          end_date: 7.days.from_now.to_date,
        )

        expect(heatmap.cells).to satisfy do
          it in [
            *,
            Analytics::Heatmap::Cell(date: ^mid_date, temperature: 1.0),
            *
          ]
        end
      end
    end

    context 'with default date range' do
      before do
        create(:license, account:, expiry: Time.current)
        create(:license, account:, expiry: 364.days.from_now)
      end

      it 'returns heatmap for the next year inclusive of today' do
        start_date = Date.current
        end_date   = 364.days.from_now.to_date

        heatmap = described_class.new(:expirations, account:)

        expect(heatmap.cells).to satisfy do
          it in [
            Analytics::Heatmap::Cell(date: ^start_date),
            *,
            Analytics::Heatmap::Cell(date: ^end_date)
          ]
        end
      end
    end
  end
end
