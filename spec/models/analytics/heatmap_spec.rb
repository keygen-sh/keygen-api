# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Heatmap do
  let(:account) { create(:account) }

  describe '.call' do
    context 'with valid type' do
      it 'returns heatmap for license expirations' do
        results = described_class.call(:expirations, account:)

        expect(results).to satisfy do |cells|
          cells.all? { it in Analytics::Heatmap::Expirations::Result(date: Date, x: Integer, y: Integer, temperature: Float, count: Integer) }
        end
      end

      it 'accepts string types' do
        results = described_class.call('expirations', account:)

        expect(results).to satisfy do |cells|
          cells.all? { it in Analytics::Heatmap::Expirations::Result(date: Date, x: Integer, y: Integer, temperature: Float, count: Integer) }
        end
      end
    end

    context 'with invalid type' do
      it 'raises HeatmapNotFoundError' do
        expect {
          described_class.call(:invalid, account:)
        }.to raise_error(Analytics::HeatmapNotFoundError)
      end
    end

    context 'with date range' do
      it 'respects custom date range' do
        start_date = Date.current
        end_date   = 30.days.from_now.to_date
        date_range = (start_date..end_date).to_a

        results = described_class.call(
          :expirations,
          account:,
          start_date:,
          end_date:,
        )

        expect(results.length).to eq(date_range.length)
        expect(results).to satisfy do
          it in [
            Analytics::Heatmap::Expirations::Result(date: ^start_date, x: Integer, y: Integer, temperature: Float, count: Integer),
            *,
            Analytics::Heatmap::Expirations::Result(date: ^end_date, x: Integer, y: Integer, temperature: Float, count: Integer)
          ]
        end
      end
    end
  end
end
