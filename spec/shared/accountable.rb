# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

shared_examples :accountable do
  let(:factory) { described_class.name.demodulize.underscore }
  let(:account) { create(:account) }

  describe '#account=' do
    context 'on create' do
      it 'should not raise when account exists' do
        expect { create(factory, account:) }.to_not raise_error
      end

      it 'should raise when account does not exist' do
        expect { create(factory, account_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when account is nil' do
        expect { create(factory, account_id: nil) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should set provided account' do
        instance = create(factory, account:)

        expect(instance.account).to eq account
      end

      context 'with current account' do
        before { Current.account = account }
        after  { Current.account = nil }

        it 'should raise when account is nil' do
          expect { create(factory, account: nil) }.to raise_error ActiveRecord::RecordInvalid
        end

        it 'should set provided account' do
          instance = create(factory, account:)

          expect(instance.account).to eq account
        end

        it 'should default to current account' do
          instance = create(factory)

          expect(instance.account).to eq Current.account
        end
      end
    end

    context 'on update' do
      it 'should raise when account exists' do
        instance = create(factory, account:)

        expect { instance.update!(account: create(:account)) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when account does not exist' do
        instance = create(factory, account:)

        expect { instance.update!(account_id: SecureRandom.uuid) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should raise when account is nil' do
        instance = create(factory, account:)

        expect { instance.update!(account: nil) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
