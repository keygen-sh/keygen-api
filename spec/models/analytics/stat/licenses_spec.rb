# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Stat::Licenses do
  let(:account) { create(:account) }

  describe '#result' do
    context 'with no licenses' do
      it 'returns zero' do
        result = described_class.new(account:).result

        expect(result).to satisfy { it in Analytics::Stat::Licenses::Result(count: 0) }
      end
    end

    context 'with global licenses' do
      before do
        create_list(:license, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        result = described_class.new(account:).result

        expect(result).to satisfy { it in Analytics::Stat::Licenses::Result(count: 3) }
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:license, 2, account:, environment:)
        create_list(:license, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped licenses' do
        result = described_class.new(account:, environment:).result

        expect(result).to satisfy { it in Analytics::Stat::Licenses::Result(count: 2) }
      end

      it 'returns only global licenses when no environment' do
        result = described_class.new(account:).result

        expect(result).to satisfy { it in Analytics::Stat::Licenses::Result(count: 3) }
      end
    end
  end
end
