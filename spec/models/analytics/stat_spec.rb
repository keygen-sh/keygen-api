# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Stat do
  let(:account) { create(:account) }

  describe '.call' do
    context 'with valid stat' do
      it 'returns results for machines stat' do
        create_list(:machine, 3, account:)

        stat = described_class.call(:machines, account:)

        expect(stat).to be_valid
        expect(stat.result).to satisfy { it in Analytics::Stat::Machines::Result(count: 3) }
      end

      it 'returns results for users stat' do
        create_list(:user, 2, account:)

        stat = described_class.call(:users, account:)

        expect(stat).to be_valid
        expect(stat.result).to satisfy { it in Analytics::Stat::Users::Result(count: 2) }
      end

      it 'returns results for licenses stat' do
        create_list(:license, 4, account:)

        stat = described_class.call(:licenses, account:)

        expect(stat).to be_valid
        expect(stat.result).to satisfy { it in Analytics::Stat::Licenses::Result(count: 4) }
      end

      it 'accepts string type names' do
        stat = described_class.call('machines', account:)

        expect(stat).to be_valid
        expect(stat.result).to satisfy { it in Analytics::Stat::Machines::Result(count: Integer) }
      end
    end

    context 'with invalid stat' do
      it 'raises StatNotFoundError' do
        expect {
          described_class.call(:invalid, account:)
        }.to raise_error(Analytics::StatNotFoundError)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'scopes to environment' do
        stat = described_class.call(:machines, account:, environment:)

        expect(stat).to be_valid
        expect(stat.result).to satisfy { it in Analytics::Stat::Machines::Result(count: 2) }
      end

      it 'returns global count when no environment' do
        stat = described_class.call(:machines, account:)

        expect(stat).to be_valid
        expect(stat.result).to satisfy { it in Analytics::Stat::Machines::Result(count: 3) }
      end
    end
  end
end
