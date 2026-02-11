# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::UsersCountQuery do
  let(:account) { create(:account) }

  describe '.call' do
    context 'with no users' do
      it 'returns zero' do
        result = described_class.call(account:)

        expect(result).to be_a(Analytics::Stat::Count)
        expect(result.count).to eq(0)
      end
    end

    context 'with global users' do
      before do
        create_list(:user, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        result = described_class.call(account:)

        expect(result).to be_a(Analytics::Stat::Count)
        expect(result.count).to eq(3)
      end
    end

    context 'with admins' do
      before do
        create_list(:user, 2, account:)
        create_list(:admin, 3, account:)
      end

      it 'excludes admins from count' do
        result = described_class.call(account:)

        expect(result.count).to eq(2)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:user, 2, account:, environment:)
        create_list(:user, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped users' do
        result = described_class.call(account:, environment:)

        expect(result.count).to eq(2)
      end

      it 'returns only global users when no environment' do
        result = described_class.call(account:)

        expect(result.count).to eq(3)
      end
    end
  end
end
