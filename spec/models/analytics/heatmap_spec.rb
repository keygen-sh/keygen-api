# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Heatmap do
  let(:account) { create(:account) }

  describe '.call' do
    context 'with valid type' do
      it 'returns results for expirations heatmap' do
        results = described_class.call(:expirations, account:)

        expect(results).to be_an(Array)
        expect(results.first).to be_a(Analytics::Heatmap::Cell)
        expect(results.first).to have_attributes(
          date: be_a(Date),
          x: be_a(Integer),
          y: be_a(Integer),
          temperature: be_a(Float),
          value: be_a(Integer),
        )
      end

      it 'accepts string type names' do
        results = described_class.call('expirations', account:)

        expect(results).to be_an(Array)
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
        results = described_class.call(
          :expirations,
          account:,
          start_date: Date.current,
          end_date: 30.days.from_now.to_date,
        )

        expect(results.length).to eq(31)
        expect(results.first.date).to eq(Date.current)
        expect(results.last.date).to eq(30.days.from_now.to_date)
      end
    end
  end
end
