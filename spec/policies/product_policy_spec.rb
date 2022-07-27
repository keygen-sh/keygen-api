# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProductPolicy, type: :policy do
  subject { described_class.new(context, product) }

  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  context 'for admin' do
  end

  context 'for product' do
  end

  context 'for license' do
  end

  context 'for user' do
    let(:context) { authorization_context(account:, bearer:, token:) }

    context 'without product license' do
      let(:bearer)  { create(:user, account:) }
      let(:token)   { create(:token, account:, bearer:) }

      it 'denies index access' do
        expect(subject).to_not permit(:index)
      end

      it 'denies show access' do
        expect(subject).to_not permit(:show)
      end

      it 'denies create access' do
        expect(subject).to_not permit(:create)
      end
    end

    context 'with product license' do
      let(:policy)   { create(:policy, account:, product:) }
      let(:licenses) { [create(:license, account:, policy:)] }
      let(:bearer)   { create(:user, account:, licenses:) }
      let(:token)    { create(:token, account:, bearer:) }

      it 'denies index access' do
        expect(subject).to_not permit(:index)
      end

      it 'denies show access' do
        expect(subject).to_not permit(:show)
      end

      it 'denies create access' do
        expect(subject).to_not permit(:create)
      end
    end
  end

  context 'for anonymous' do
    let(:context) { authorization_context(account:) }

    it 'denies index access' do
      expect(subject).to_not permit(:index)
    end

    it 'denies show access' do
      expect(subject).to_not permit(:show)
    end

    it 'denies create access' do
      expect(subject).to_not permit(:create)
    end
  end
end
