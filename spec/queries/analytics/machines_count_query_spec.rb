# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::MachinesCountQuery do
  let(:account) { create(:account) }

  describe '.call' do
    context 'with no machines' do
      it 'returns zero' do
        result = described_class.call(account:)

        expect(result).to satisfy { it in Analytics::MachinesCountQuery::Result(count: 0) }
      end
    end

    context 'with global machines' do
      before do
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        result = described_class.call(account:)

        expect(result).to satisfy { it in Analytics::MachinesCountQuery::Result(count: 3) }
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped machines' do
        result = described_class.call(account:, environment:)

        expect(result).to satisfy { it in Analytics::MachinesCountQuery::Result(count: 2) }
      end

      it 'returns only global machines when no environment' do
        result = described_class.call(account:)

        expect(result).to satisfy { it in Analytics::MachinesCountQuery::Result(count: 3) }
      end
    end
  end
end
