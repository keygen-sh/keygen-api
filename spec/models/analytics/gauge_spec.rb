# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Gauge do
  let(:account) { create(:account) }

  describe '.new' do
    context 'with valid gauge' do
      it 'returns gauge for machines' do
        create_list(:machine, 3, account:)

        gauge = described_class.new(:machines, account:)

        expect(gauge).to be_a(Analytics::Gauge)
        expect(gauge).to be_valid
        expect(gauge.count).to eq(3)
      end

      it 'returns gauge for users' do
        create_list(:user, 2, account:)

        gauge = described_class.new(:users, account:)

        expect(gauge).to be_a(Analytics::Gauge)
        expect(gauge).to be_valid
        expect(gauge.count).to eq(2)
      end

      it 'returns gauge for licenses' do
        create_list(:license, 4, account:)

        gauge = described_class.new(:licenses, account:)

        expect(gauge).to be_a(Analytics::Gauge)
        expect(gauge).to be_valid
        expect(gauge.count).to eq(4)
      end

      it 'accepts string names' do
        gauge = described_class.new('machines', account:)

        expect(gauge).to be_a(Analytics::Gauge)
        expect(gauge).to be_valid
      end
    end

    context 'with invalid gauge' do
      it 'raises error' do
        expect { described_class.new(:invalid, account:) }.to raise_error(Analytics::GaugeNotFoundError)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'scopes to environment' do
        gauge = described_class.new(:machines, account:, environment:)

        expect(gauge).to be_valid
        expect(gauge.count).to eq(2)
      end

      it 'returns global count when no environment' do
        gauge = described_class.new(:machines, account:)

        expect(gauge).to be_valid
        expect(gauge.count).to eq(3)
      end
    end
  end

  describe 'machines' do
    context 'with no machines' do
      it 'returns zero' do
        gauge = described_class.new(:machines, account:)

        expect(gauge.count).to eq(0)
      end
    end

    context 'with machines' do
      before { create_list(:machine, 3, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:machines, account:)

        expect(gauge.count).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped count' do
        gauge = described_class.new(:machines, account:, environment:)

        expect(gauge.count).to eq(2)
      end

      it 'returns only global count when no environment' do
        gauge = described_class.new(:machines, account:)

        expect(gauge.count).to eq(3)
      end
    end
  end

  describe 'licenses' do
    context 'with no licenses' do
      it 'returns zero' do
        gauge = described_class.new(:licenses, account:)

        expect(gauge.count).to eq(0)
      end
    end

    context 'with licenses' do
      before { create_list(:license, 3, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:licenses, account:)

        expect(gauge.count).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:license, 2, account:, environment:)
        create_list(:license, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped count' do
        gauge = described_class.new(:licenses, account:, environment:)

        expect(gauge.count).to eq(2)
      end

      it 'returns only global count when no environment' do
        gauge = described_class.new(:licenses, account:)

        expect(gauge.count).to eq(3)
      end
    end
  end

  describe 'users' do
    context 'with no users' do
      it 'returns zero' do
        gauge = described_class.new(:users, account:)

        expect(gauge.count).to eq(0)
      end
    end

    context 'with users' do
      before { create_list(:user, 3, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:users, account:)

        expect(gauge.count).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:user, 2, account:, environment:)
        create_list(:user, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped count' do
        gauge = described_class.new(:users, account:, environment:)

        expect(gauge.count).to eq(2)
      end

      it 'returns only global count when no environment' do
        gauge = described_class.new(:users, account:)

        expect(gauge.count).to eq(3)
      end
    end
  end

  describe 'active_licensed_users' do
    context 'with no licenses' do
      it 'returns zero' do
        gauge = described_class.new(:active_licensed_users, account:)

        expect(gauge.count).to eq(0)
      end
    end

    context 'with active licensed users' do
      before { create_list(:license, 5, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:active_licensed_users, account:)

        expect(gauge.count).to eq(5)
      end
    end

    context 'with environment parameter' do
      let(:environment) { create(:environment, account:) }

      before { create_list(:license, 3, account:) }

      it 'ignores environment scoping' do
        gauge = described_class.new(:active_licensed_users, account:, environment:)

        expect(gauge.count).to eq(3)
      end
    end
  end

  describe 'alus' do
    before { create_list(:license, 2, account:) }

    it 'is an alias for active_licensed_users' do
      gauge = described_class.new(:alus, account:)

      expect(gauge.count).to eq(2)
    end
  end
end
