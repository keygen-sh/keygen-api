# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Stat do
  let(:account) { create(:account) }

  describe '.new' do
    context 'with valid stat' do
      it 'returns stat for machines' do
        create_list(:machine, 3, account:)

        stat = described_class.new(:machines, account:)

        expect(stat).to be_a(Analytics::Stat)
        expect(stat).to be_valid
        expect(stat.count).to eq(3)
      end

      it 'returns stat for users' do
        create_list(:user, 2, account:)

        stat = described_class.new(:users, account:)

        expect(stat).to be_a(Analytics::Stat)
        expect(stat).to be_valid
        expect(stat.count).to eq(2)
      end

      it 'returns stat for licenses' do
        create_list(:license, 4, account:)

        stat = described_class.new(:licenses, account:)

        expect(stat).to be_a(Analytics::Stat)
        expect(stat).to be_valid
        expect(stat.count).to eq(4)
      end

      it 'accepts string names' do
        stat = described_class.new('machines', account:)

        expect(stat).to be_a(Analytics::Stat)
        expect(stat).to be_valid
      end
    end

    context 'with invalid stat' do
      it 'raises error' do
        expect { described_class.new(:invalid, account:) }.to raise_error(Analytics::StatNotFoundError)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'scopes to environment' do
        stat = described_class.new(:machines, account:, environment:)

        expect(stat).to be_valid
        expect(stat.count).to eq(2)
      end

      it 'returns global count when no environment' do
        stat = described_class.new(:machines, account:)

        expect(stat).to be_valid
        expect(stat.count).to eq(3)
      end
    end
  end

  describe 'machines' do
    context 'with no machines' do
      it 'returns zero' do
        stat = described_class.new(:machines, account:)

        expect(stat.count).to eq(0)
      end
    end

    context 'with global machines' do
      before do
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        stat = described_class.new(:machines, account:)

        expect(stat.count).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:machine, 2, account:, environment:)
        create_list(:machine, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped machines' do
        stat = described_class.new(:machines, account:, environment:)

        expect(stat.count).to eq(2)
      end

      it 'returns only global machines when no environment' do
        stat = described_class.new(:machines, account:)

        expect(stat.count).to eq(3)
      end
    end
  end

  describe 'licenses' do
    context 'with no licenses' do
      it 'returns zero' do
        stat = described_class.new(:licenses, account:)

        expect(stat.count).to eq(0)
      end
    end

    context 'with global licenses' do
      before do
        create_list(:license, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        stat = described_class.new(:licenses, account:)

        expect(stat.count).to eq(3)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:license, 2, account:, environment:)
        create_list(:license, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped licenses' do
        stat = described_class.new(:licenses, account:, environment:)

        expect(stat.count).to eq(2)
      end

      it 'returns only global licenses when no environment' do
        stat = described_class.new(:licenses, account:)

        expect(stat.count).to eq(3)
      end
    end
  end

  describe 'users' do
    context 'with no users' do
      it 'returns zero' do
        stat = described_class.new(:users, account:)

        expect(stat.count).to eq(0)
      end
    end

    context 'with global users' do
      before do
        create_list(:user, 3, account:, environment: nil)
      end

      it 'returns correct count' do
        stat = described_class.new(:users, account:)

        expect(stat.count).to eq(3)
      end
    end

    context 'with admins' do
      before do
        create_list(:user, 2, account:)
        create_list(:admin, 3, account:)
      end

      it 'excludes admins from count' do
        stat = described_class.new(:users, account:)

        expect(stat.count).to eq(2)
      end
    end

    context 'with environment scoping' do
      let(:environment) { create(:environment, account:) }

      before do
        create_list(:user, 2, account:, environment:)
        create_list(:user, 3, account:, environment: nil)
      end

      it 'returns only environment-scoped users' do
        stat = described_class.new(:users, account:, environment:)

        expect(stat.count).to eq(2)
      end

      it 'returns only global users when no environment' do
        stat = described_class.new(:users, account:)

        expect(stat.count).to eq(3)
      end
    end
  end

  describe 'active_licensed_users' do
    context 'with no active licensed users' do
      it 'returns zero' do
        stat = described_class.new(:active_licensed_users, account:)

        expect(stat.count).to eq(0)
      end
    end

    context 'with users without licenses' do
      before do
        create_list(:user, 3, account:)
      end

      it 'returns zero' do
        stat = described_class.new(:active_licensed_users, account:)

        expect(stat.count).to eq(0)
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
        stat = described_class.new(:active_licensed_users, account:)

        expect(stat.count).to eq(3)
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
        stat = described_class.new(:active_licensed_users, account:)

        expect(stat.count).to eq(2)
      end
    end

    context 'with unassigned licenses' do
      before do
        create_list(:license, 3, account:)
      end

      it 'counts each unassigned license as one licensed user' do
        stat = described_class.new(:active_licensed_users, account:)

        expect(stat.count).to eq(3)
      end
    end

    context 'with environment parameter' do
      let(:environment) { create(:environment, account:) }

      before do
        user = create(:user, account:, environment:)
        create(:license, account:, environment:, owner: user)
      end

      it 'ignores environment scoping' do
        stat = described_class.new(:active_licensed_users, account:, environment:)

        expect(stat.count).to eq(1)
      end
    end
  end

  describe 'alus' do
    it 'is an alias for active_licensed_users' do
      users = create_list(:user, 2, account:)
      users.each { create(:license, account:, owner: it) }

      stat = described_class.new(:alus, account:)

      expect(stat.count).to eq(2)
    end
  end
end
