# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::ActiveLicensedUsersCountQuery do
  let(:account) { create(:account) }

  describe '.call' do
    context 'with no active licensed users' do
      it 'returns zero' do
        result = described_class.call(account:)

        expect(result).to be_a(Analytics::Stat::Count)
        expect(result.count).to eq(0)
      end
    end

    context 'with users without licenses' do
      before do
        create_list(:user, 3, account:)
      end

      it 'returns zero' do
        result = described_class.call(account:)

        expect(result.count).to eq(0)
      end
    end

    context 'with active licensed users' do
      before do
        users = create_list(:user, 3, account:)
        users.each do |user|
          create(:license, account:, owner: user)
        end
      end

      it 'returns correct count' do
        result = described_class.call(account:)

        expect(result).to be_a(Analytics::Stat::Count)
        expect(result.count).to eq(3)
      end
    end

    context 'with expired but recently created licenses' do
      before do
        users = create_list(:user, 2, account:)
        users.each do |user|
          create(:license, account:, owner: user, expiry: 1.day.ago)
        end
      end

      it 'counts users with expired but recently active licenses' do
        result = described_class.call(account:)

        expect(result.count).to eq(2)
      end
    end

    context 'with unassigned licenses' do
      before do
        create_list(:license, 3, account:)
      end

      it 'counts each unassigned license as one licensed user' do
        result = described_class.call(account:)

        expect(result.count).to eq(3)
      end
    end

    context 'with environment parameter' do
      let(:environment) { create(:environment, account:) }

      before do
        user = create(:user, account:, environment:)
        create(:license, account:, environment:, owner: user)
      end

      it 'ignores environment scoping' do
        result = described_class.call(account:, environment:)

        expect(result.count).to eq(1)
      end
    end
  end
end
