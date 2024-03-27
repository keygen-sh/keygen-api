# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleasePackage, type: :model do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)
        package     = create(:package, account:, product:)

        expect(package.environment).to eq product.environment
      end

      it 'should not raise when environment matches product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)

        expect { create(:package, account:, environment:, product:) }.to_not raise_error
      end

      it 'should raise when environment does not match product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment: nil)

        expect { create(:package, account:, environment:, product:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches product' do
        environment = create(:environment, account:)
        package     = create(:package, account:, environment:)

        expect { package.update!(product: create(:product, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match product' do
        environment = create(:environment, account:)
        package     = create(:package, account:, environment:)

        expect { package.update!(product: create(:product, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
