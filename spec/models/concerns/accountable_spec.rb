# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Accountable, type: :concern do
  let(:account) { create(:account) }

  describe '.has_account' do
    let(:accountable) {
      Class.new ActiveRecord::Base do
        def self.table_name = 'licenses'
        def self.name       = 'License'

        include Accountable
      end
    }

    it 'should not raise' do
      expect { accountable.has_account }.to_not raise_error
    end

    it 'should define an account association' do
      accountable.has_account

      association = accountable.reflect_on_association(:account)

      expect(association).to_not be_nil
    end

    it 'should define an account association with options' do
      accountable.has_account inverse_of: :licenses, foreign_key: :account_id

      association = accountable.reflect_on_association(:account)

      expect(association.options).to include(
        foreign_key: :account_id,
        inverse_of: :licenses,
      )
    end

    context 'with incorrect usage' do
      it 'should not warn on belongs_to defined before account' do
        expect {
          accountable.belongs_to :user
          accountable.has_account
        }.to_not log anything
      end

      it 'should warn on belongs_to defined after account' do
        expect {
          accountable.has_account
          accountable.belongs_to :user
        }.to log.warning <<~MSG
          A .belongs_to(:user) association was defined after .has_account() was called.
        MSG
      end
    end

    context 'without default' do
      before { accountable.has_account }

      it 'should have a nil default' do
        instance = accountable.new

        expect(instance.account_id).to be_nil
        expect(instance.account).to be_nil
      end
    end

    context 'with default' do
      let(:account) { create(:account) }

      context 'with current' do
        before {
          Current.account = account

          accountable.has_account default: -> { nil }
        }

        after {
          Current.account = nil
        }

        it 'should have an account default' do
          instance = accountable.new

          expect(instance.account_id).to eq account.id
          expect(instance.account).to eq account
        end
      end

      context 'with string' do
        before {
          acct = account # close over account

          accountable.has_account default: -> { acct.id }
        }

        it 'should have an account default' do
          instance = accountable.new

          expect(instance.account_id).to eq account.id
          expect(instance.account).to eq account
        end
      end

      context 'with class' do
        before {
          acct = account # close over account

          accountable.has_account default: -> { acct }
        }

        it 'should have an account default' do
          instance = accountable.new

          expect(instance.account_id).to eq account.id
          expect(instance.account).to eq account
        end
      end

      context 'with other' do
        before {
          accountable.has_account default: -> { Class.new }
        }

        it 'should have an account default' do
          expect { accountable.new }.to raise_error NoMatchingPatternError
        end
      end
    end
  end

  # NOTE(ezekg) See :accountable shared examples for more tests
end
