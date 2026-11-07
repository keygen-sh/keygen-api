# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Policy, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#duration_for' do
    shared_examples 'duration-aware policy arithmetic' do
      it 'should preserve calendar arithmetic by default' do
        policy = create(:policy, account:, duration: 90 * 86_400)

        expect(policy.duration_strategy).to eq 'CALENDAR'
        expect(Time.utc(2026, 10, 9) + policy.duration_for).to eq Time.utc(2027, 1, 7, 3, 1, 48)
      end

      it 'should preserve calendar arithmetic for existing policies without a strategy' do
        policy = create(:policy, account:, duration: 90 * 86_400)
        policy.update_column(:duration_strategy, nil)

        expect(Time.utc(2026, 10, 9) + policy.reload.duration_for).to eq Time.utc(2027, 1, 7, 3, 1, 48)
        expect(policy.duration_strategy).to be_nil
      end

      [Time.utc(2026, 10, 9), Time.utc(2026, 1, 31), Time.utc(2028, 2, 29)].each do |start|
        [30, 90, 365].each do |days|
          it "should add exactly #{days} days in seconds from #{start.iso8601}" do
            policy = build(:policy, duration_strategy: 'SECONDS', duration: days * 86_400)

            expect((start + policy.duration_for) - start).to eq days * 86_400
          end
        end
      end

      it 'should preserve exact elapsed seconds across daylight saving changes' do
        policy = build(:policy, duration_strategy: 'SECONDS')

        Time.use_zone('America/New_York') do
          [Time.zone.local(2026, 3, 7, 12), Time.zone.local(2026, 10, 31, 12)].each do |start|
            expect((start + policy.duration_for(86_400)) - start).to eq 86_400
          end
        end
      end

      it 'should treat Rails duration inputs as seconds when opted in' do
        policy = build(:policy, duration_strategy: 'SECONDS')
        start  = Time.utc(2026, 1, 31)

        expect((start + policy.duration_for(1.month)) - start).to eq 2_629_746
      end

      it 'should reject unsupported duration strategies' do
        policy = build(:policy, account:, duration_strategy: 'HOURS')

        expect(policy).to_not be_valid
        expect(policy.errors[:duration_strategy]).to include 'unsupported duration strategy'
      end
    end

    within_ce do
      it_behaves_like 'duration-aware policy arithmetic'
    end

    within_ee do
      it_behaves_like 'duration-aware policy arithmetic'
    end
  end

  describe '#environment=', only: :ee do
    context 'on create' do
      it 'should apply default environment matching product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)
        policy      = create(:policy, account:, product:)

        expect(policy.environment).to eq product.environment
      end

      it 'should not raise when environment matches product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)

        expect { create(:policy, account:, environment:, product:) }.to_not raise_error
      end

      it 'should raise when environment does not match product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment: nil)

        expect { create(:policy, account:, environment:, product:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches product' do
        environment = create(:environment, account:)
        policy      = create(:policy, account:, environment:)

        expect { policy.update!(product: create(:product, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match product' do
        environment = create(:environment, account:)
        policy      = create(:policy, account:, environment:)

        expect { policy.update!(product: create(:product, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#product=' do
    context 'on build' do
      it 'should denormalize product to licenses' do
        product = create(:product, account:)
        policy = build(:policy, product:, account:, licenses: build_list(:license, 10, account:))

        policy.licenses.each do |license|
          expect(license.product_id).to eq policy.product_id
        end
      end
    end

    context 'on create' do
      it 'should denormalize product to licenses' do
        product = create(:product, account:)
        policy = create(:policy, product:, account:, licenses: build_list(:license, 10, account:))

        policy.licenses.each do |license|
          expect(license.product_id).to eq policy.product_id
        end
      end
    end

    context 'on update' do
      before { Sidekiq::Testing.inline! }
      after  { Sidekiq::Testing.fake! }

      it 'should denormalize product to licenses' do
        product = create(:product, account:)
        policy  = create(:policy, account:, licenses: build_list(:license, 10, account:))

        perform_enqueued_jobs only: Denormalizable::DenormalizeAsyncJob do
          policy.update!(product:)
        end

        policy.reload.licenses.each do |license|
          expect(license.product_id).to eq policy.product_id
        end
      end

      it "should not denormalize product to other policies' licenses" do
        policy = create(:policy, account:, licenses: build_list(:license, 3, account:))
        other  = create(:policy, account:, licenses: build_list(:license, 3, account:))

        perform_enqueued_jobs only: Denormalizable::DenormalizeAsyncJob do
          policy.update!(product: create(:product, account:))
        end

        policy.reload.licenses.each do |license|
          expect(license.product_id).to eq policy.product_id
        end

        other.reload.licenses.each do |license|
          expect(license.product_id).to eq other.product_id
        end
      end
    end
  end
end
