# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Role, type: :model do
  let(:account)  { create(:account) }
  let(:resource) { create(:user, account:) }

  subject { resource.role }

  describe 'pattern matching' do
    context 'with admin role' do
      let(:resource) { create(:admin, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be true
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be true
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with user role' do
      let(:resource) { create(:user, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be true
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be true
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with environment role' do
      let(:resource) { create(:environment, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be true
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be true
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with product role' do
      let(:resource) { create(:product, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be true
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be true
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with license role' do
      let(:resource) { create(:license, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be true
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be true
      end
    end
  end
end
