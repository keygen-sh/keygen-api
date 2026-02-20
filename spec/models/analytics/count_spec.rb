# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Count do
  let(:account) { create(:account) }

  describe '.new' do
    context 'with valid count' do
      it 'returns count for machines' do
        create_list(:machine, 3, account:)

        count = described_class.new(:machines, account:)

        expect(count).to be_a(Analytics::Count)
        expect(count).to be_valid
        expect(count.count).to eq(3)
      end

      it 'returns count for users' do
        create_list(:user, 2, account:)

        count = described_class.new(:users, account:)

        expect(count).to be_a(Analytics::Count)
        expect(count).to be_valid
        expect(count.count).to eq(2)
      end

      it 'returns count for licenses' do
        create_list(:license, 4, account:)

        count = described_class.new(:licenses, account:)

        expect(count).to be_a(Analytics::Count)
        expect(count).to be_valid
        expect(count.count).to eq(4)
      end

      it 'accepts string names' do
        count = described_class.new('machines', account:)

        expect(count).to be_a(Analytics::Count)
        expect(count).to be_valid
      end
    end

    context 'with invalid count' do
      it 'raises error' do
        expect { described_class.new(:invalid, account:) }.to raise_error(Analytics::CountNotFoundError)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'scopes to environment' do
        count = described_class.new(:machines, account:, environment:)

        expect(count).to be_valid
        expect(count.count).to eq(2)
      end

      it 'returns global count when no environment' do
        count = described_class.new(:machines, account:)

        expect(count).to be_valid
        expect(count.count).to eq(3)
      end
    end
  end

  describe 'machines' do
    context 'with no machines' do
      it 'returns zero' do
        count = described_class.new(:machines, account:)

        expect(count.count).to eq(0)
      end
    end

    context 'with global machines' do
      before do
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        count = described_class.new(:machines, account:)

        expect(count.count).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped machines' do
        count = described_class.new(:machines, account:, environment:)

        expect(count.count).to eq(2)
      end

      it 'returns only global machines when no environment' do
        count = described_class.new(:machines, account:)

        expect(count.count).to eq(3)
      end
    end
  end

  describe 'licenses' do
    context 'with no licenses' do
      it 'returns zero' do
        count = described_class.new(:licenses, account:)

        expect(count.count).to eq(0)
      end
    end

    context 'with global licenses' do
      before do
        create_list(:license, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        count = described_class.new(:licenses, account:)

        expect(count.count).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:license, 2, account:, environment:)
        create_list(:license, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped licenses' do
        count = described_class.new(:licenses, account:, environment:)

        expect(count.count).to eq(2)
      end

      it 'returns only global licenses when no environment' do
        count = described_class.new(:licenses, account:)

        expect(count.count).to eq(3)
      end
    end
  end

  describe 'users' do
    context 'with no users' do
      it 'returns zero' do
        count = described_class.new(:users, account:)

        expect(count.count).to eq(0)
      end
    end

    context 'with global users' do
      before do
        create_list(:user, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        count = described_class.new(:users, account:)

        expect(count.count).to eq(3)
      end
    end

    context 'with admins' do
      before do
        create_list(:user, 2, account:)
        create_list(:admin, 3, account:)
      end

      it 'excludes admins from count' do
        count = described_class.new(:users, account:)

        expect(count.count).to eq(2)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:user, 2, account:, environment:)
        create_list(:user, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped users' do
        count = described_class.new(:users, account:, environment:)

        expect(count.count).to eq(2)
      end

      it 'returns only global users when no environment' do
        count = described_class.new(:users, account:)

        expect(count.count).to eq(3)
      end
    end
  end

  describe 'active_licensed_users' do
    context 'with no active licensed users' do
      it 'returns zero' do
        count = described_class.new(:active_licensed_users, account:)

        expect(count.count).to eq(0)
      end
    end

    context 'with users without licenses' do
      before do
        create_list(:user, 3, account:)
      end

      it 'returns zero' do
        count = described_class.new(:active_licensed_users, account:)

        expect(count.count).to eq(0)
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
        count = described_class.new(:active_licensed_users, account:)

        expect(count.count).to eq(3)
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
        count = described_class.new(:active_licensed_users, account:)

        expect(count.count).to eq(2)
      end
    end

    context 'with unassigned licenses' do
      before do
        create_list(:license, 3, account:)
      end

      it 'counts each unassigned license as one licensed user' do
        count = described_class.new(:active_licensed_users, account:)

        expect(count.count).to eq(3)
      end
    end

    context 'with environment parameter' do
      let(:environment) { create(:environment, account:) }

      before do
        user = create(:user, account:, environment:)
        create(:license, account:, environment:, owner: user)
      end

      it 'ignores environment scoping' do
        count = described_class.new(:active_licensed_users, account:, environment:)

        expect(count.count).to eq(1)
      end
    end
  end

  describe 'alus' do
    it 'is an alias for active_licensed_users' do
      users = create_list(:user, 2, account:)
      users.each { create(:license, account:, owner: it) }

      count = described_class.new(:alus, account:)

      expect(count.count).to eq(2)
    end
  end
end
