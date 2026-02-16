# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Event do
  let(:account) { create(:account) }

  describe '.call', :only_clickhouse do
    it 'returns event count' do
      result = described_class.call(
        'license.validation.succeeded',
        account:,
        start_date: 7.days.ago.to_date,
        end_date: Date.current,
      )

      expect(result).to satisfy do
        it in [
          Analytics::EventCountQuery::Result(event: 'license.validation.succeeded', count: Integer)
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
        counts.all? { it in Analytics::EventCountQuery::Result(event: /\Alicense\./, count: Integer) }
      end
    end
  end
end
