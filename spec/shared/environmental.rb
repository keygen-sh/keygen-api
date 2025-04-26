# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

shared_examples :environmental, only: :ee do
  let(:factory) { described_class.name.demodulize.underscore }
  let(:account) { create(:account) }

  describe '#environment=', only: :ee do
    context 'on create' do
      it 'should not raise when environment exists' do
        environment = create(:environment, account:)

        expect { create(factory, account:, environment:) }.to_not raise_error
      end

      it 'should raise when environment does not exist' do
        expect { create(factory, account:, environment_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment is nil' do
        expect { create(factory, account:, environment: nil) }.to_not raise_error
      end

      it 'should set provided environment' do
        environment = create(:environment, account:)
        instance    = create(factory, account:, environment:)

        expect(instance.environment).to eq environment
      end

      it 'should set nil environment' do
        instance = create(factory, account:, environment: nil)

        expect(instance.environment).to be_nil
      end

      context 'with current environment' do
        before { Current.environment = create(:environment, account:) }
        after  { Current.environment = nil }

        it 'should set provided environment' do
          environment = create(:environment, account:)
          instance    = create(factory, account:, environment:)

          expect(instance.environment).to eq environment
        end

        it 'should default to current environment' do
          instance = create(factory, account:)

          expect(instance.environment).to eq Current.environment
        end

        it 'should set nil environment' do
          instance = create(factory, account:, environment: nil)

          expect(instance.environment).to be_nil
        end
      end
    end

    context 'on update' do
      it 'should raise when environment exists' do
        environment = create(:environment, account:)
        instance    = create(factory, account:, environment:)

        expect { instance.update!(environment: create(:environment, account:)) }.to raise_error ActiveRecord::RecordInvalid
        expect { instance.update!(environment: nil) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when environment does not exist' do
        environment = create(:environment, account:)
        instance    = create(factory, account:, environment:)

        expect { instance.update!(environment_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when environment is nil' do
        instance = create(factory, account:, environment: nil)

        expect { instance.update!(environment: create(:environment, account:)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
