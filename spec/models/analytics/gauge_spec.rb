# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Gauge do
  let(:account) { create(:account) }

  describe '.new' do
    context 'with valid gauge' do
      it 'returns gauge for machines' do
        gauge = described_class.new(:machines, account:)

        expect(gauge).to be_an Analytics::Gauge
        expect(gauge).to be_valid
      end

      it 'returns gauge for users' do
        gauge = described_class.new(:users, account:)

        expect(gauge).to be_an Analytics::Gauge
        expect(gauge).to be_valid
      end

      it 'returns gauge for licenses' do
        gauge = described_class.new(:licenses, account:)

        expect(gauge).to be_an Analytics::Gauge
        expect(gauge).to be_valid
      end

      it 'returns gauge for validations', :only_clickhouse do
        gauge = described_class.new(:validations, account:)

        expect(gauge).to be_an Analytics::Gauge
        expect(gauge).to be_valid
      end

      it 'accepts string names' do
        gauge = described_class.new('machines', account:)

        expect(gauge).to be_an Analytics::Gauge
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
        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'machines', count: 2)]
        end
      end

      it 'returns global count when no environment' do
        gauge = described_class.new(:machines, account:)

        expect(gauge).to be_valid
        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'machines', count: 3)]
        end
      end
    end
  end

  describe 'machines' do
    context 'with no machines' do
      it 'returns zero' do
        gauge = described_class.new(:machines, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'machines', count: 0)]
        end
      end
    end

    context 'with machines' do
      before { create_list(:machine, 3, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:machines, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'machines', count: 3)]
        end
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

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'machines', count: 2)]
        end
      end

      it 'returns only global count when no environment' do
        gauge = described_class.new(:machines, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'machines', count: 3)]
        end
      end
    end
  end

  describe 'licenses' do
    context 'with no licenses' do
      it 'returns zero' do
        gauge = described_class.new(:licenses, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'licenses', count: 0)]
        end
      end
    end

    context 'with licenses' do
      before { create_list(:license, 3, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:licenses, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'licenses', count: 3)]
        end
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

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'licenses', count: 2)]
        end
      end

      it 'returns only global count when no environment' do
        gauge = described_class.new(:licenses, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'licenses', count: 3)]
        end
      end
    end
  end

  describe 'users' do
    context 'with no users' do
      it 'returns zero' do
        gauge = described_class.new(:users, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'users', count: 0)]
        end
      end
    end

    context 'with users' do
      before { create_list(:user, 3, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:users, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'users', count: 3)]
        end
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

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'users', count: 2)]
        end
      end

      it 'returns only global count when no environment' do
        gauge = described_class.new(:users, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'users', count: 3)]
        end
      end
    end
  end

  describe 'active_licensed_users' do
    context 'with no licenses' do
      it 'returns zero' do
        gauge = described_class.new(:alus, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'alus', count: 0)]
        end
      end
    end

    context 'with active licensed users' do
      before { create_list(:license, 5, account:) }

      it 'returns correct count' do
        gauge = described_class.new(:alus, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'alus', count: 5)]
        end
      end
    end

    context 'with environment parameter' do
      let(:environment) { create(:environment, account:) }

      before { create_list(:license, 3, account:) }

      it 'ignores environment scoping' do
        gauge = described_class.new(:alus, account:, environment:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'alus', count: 3)]
        end
      end
    end
  end

  describe 'validations', :only_clickhouse do
    before { Sidekiq::Testing.inline! }
    after  { Sidekiq::Testing.fake! }

    context 'with no validations' do
      it 'returns empty measurements' do
        gauge = described_class.new(:validations, account:)

        expect(gauge.measurements).to be_empty
      end
    end

    context 'with validations' do
      before do
        license = create(:license, account:)

        create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license, metadata: { code: 'VALID' })
        create_list(:event_log, 2, :license_validation_failed,    account:, resource: license, metadata: { code: 'EXPIRED' })
      end

      it 'returns measurements' do
        gauge = described_class.new(:validations, account:)

        expect(gauge.measurements).to satisfy do
          it in [
            Analytics::Gauge::Measurement(metric: 'validations.expired', count: 2),
            Analytics::Gauge::Measurement(metric: 'validations.valid',   count: 3),
          ]
        end
      end
    end

    context 'with license filtering' do
      let(:license1) { create(:license, account:) }
      let(:license2) { create(:license, account:) }

      before do
        create_list(:event_log, 3, :license_validation_succeeded, account:, resource: license1, metadata: { code: 'VALID' })
        create_list(:event_log, 2, :license_validation_failed,    account:, resource: license2, metadata: { code: 'EXPIRED' })
      end

      it 'filters by license' do
        gauge = described_class.new(:validations, account:, license_id: license1.id)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'validations.valid', count: 3)]
        end
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        scoped_license = create(:license, account:, environment:)
        global_license = create(:license, account:, environment: nil)

        create_list(:event_log, 3, :license_validation_succeeded, account:, resource: scoped_license, environment:,     metadata: { code: 'VALID' })
        create_list(:event_log, 2, :license_validation_succeeded, account:, resource: global_license, environment: nil, metadata: { code: 'VALID' })
      end

      it 'returns only environment-scoped measurements' do
        gauge = described_class.new(:validations, account:, environment:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'validations.valid', count: 3)]
        end
      end

      it 'returns only global measurements when no environment' do
        gauge = described_class.new(:validations, account:)

        expect(gauge.measurements).to satisfy do
          it in [Analytics::Gauge::Measurement(metric: 'validations.valid', count: 2)]
        end
      end
    end
  end
end
