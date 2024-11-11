# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Policy, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=' do
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

        perform_enqueued_jobs only: Denormalizable::DenormalizeAssociationAsyncJob do
          policy.update!(product:)
        end

        policy.reload.licenses.each do |license|
          expect(license.product_id).to eq policy.product_id
        end
      end
    end
  end
end
