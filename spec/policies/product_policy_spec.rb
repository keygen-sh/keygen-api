# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProductPolicy, type: :policy do
  subject { described_class.new(context, product) }

  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  context 'for admin' do
    let(:context) { authorization_context(account:, bearer:, token:) }
    let(:token)  { create(:token, account:, bearer:) }

    context 'without permission' do
      let(:bearer) { create(:admin, account:, permissions: []) }

      it 'permits index access' do
        expect(subject).to permit(:index)
      end

      it 'permits show access' do
        expect(subject).to permit(:show)
      end

      it 'permits create access' do
        expect(subject).to permit(:create)
      end

      it 'permits update access' do
        expect(subject).to permit(:update)
      end

      it 'permits destroy access' do
        expect(subject).to permit(:destroy)
      end
    end

    context 'with permission' do
      let(:bearer) { create(:admin, account:) }

      it 'permits index access' do
        expect(subject).to permit(:index)
      end

      it 'permits show access' do
        expect(subject).to permit(:show)
      end

      it 'permits create access' do
        expect(subject).to permit(:create)
      end

      it 'permits update access' do
        expect(subject).to permit(:update)
      end

      it 'permits destroy access' do
        expect(subject).to permit(:destroy)
      end
    end
  end

  context 'for product' do
    let(:context) { authorization_context(account:, bearer:, token:) }

    context 'other product' do
      let(:bearer) { create(:product, account:) }
      let(:token)  { create(:token, account:, bearer:) }

      it 'denies index access' do
        expect(subject).to_not permit(:index)
      end

      it 'denies show access' do
        expect(subject).to_not permit(:show)
      end

      it 'denies create access' do
        expect(subject).to_not permit(:create)
      end

      it 'denies update access' do
        expect(subject).to_not permit(:update)
      end

      it 'denies destroy access' do
        expect(subject).to_not permit(:destroy)
      end
    end

    context 'this product' do
      let(:bearer) { product }
      let(:token)  { create(:token, account:, bearer:) }

      it 'permits index access' do
        expect(subject).to_not permit(:index)
      end

      it 'permits show access' do
        expect(subject).to permit(:show)
      end

      it 'permits create access' do
        expect(subject).to_not permit(:create)
      end

      it 'denies update access' do
        expect(subject).to permit(:update)
      end

      it 'denies destroy access' do
        expect(subject).to_not permit(:destroy)
      end
    end
  end

  context 'for license' do
    context 'for other product' do
      let(:bearer) { create(:license, account:) }

      context 'with token' do
        let(:token)   { create(:token, account:, bearer:) }
        let(:context) { authorization_context(account:, bearer:, token:) }

        it 'denies index access' do
          expect(subject).to_not permit(:index)
        end

        it 'denies show access' do
          expect(subject).to_not permit(:show)
        end

        it 'denies create access' do
          expect(subject).to_not permit(:create)
        end

        it 'denies update access' do
          expect(subject).to_not permit(:update)
        end

        it 'denies destroy access' do
          expect(subject).to_not permit(:destroy)
        end
      end

      context 'with key' do
        let(:context) { authorization_context(account:, bearer:) }

        it 'denies index access' do
          expect(subject).to_not permit(:index)
        end

        it 'denies show access' do
          expect(subject).to_not permit(:show)
        end

        it 'denies create access' do
          expect(subject).to_not permit(:create)
        end

        it 'denies update access' do
          expect(subject).to_not permit(:update)
        end

        it 'denies destroy access' do
          expect(subject).to_not permit(:destroy)
        end
      end
    end

    context 'for product' do
      let(:policy) { create(:policy, account:, product:) }
      let(:bearer) { create(:license, account:, policy:) }

      context 'with token' do
        let(:token)   { create(:token, account:, bearer:) }
        let(:context) { authorization_context(account:, bearer:, token:) }

        it 'denies index access' do
          expect(subject).to_not permit(:index)
        end

        it 'denies show access' do
          expect(subject).to_not permit(:show)
        end

        it 'denies create access' do
          expect(subject).to_not permit(:create)
        end

        it 'denies update access' do
          expect(subject).to_not permit(:update)
        end

        it 'denies destroy access' do
          expect(subject).to_not permit(:destroy)
        end
      end

      context 'with key' do
        let(:context) { authorization_context(account:, bearer:) }

        it 'denies index access' do
          expect(subject).to_not permit(:index)
        end

        it 'denies show access' do
          expect(subject).to_not permit(:show)
        end

        it 'denies create access' do
          expect(subject).to_not permit(:create)
        end

        it 'denies update access' do
          expect(subject).to_not permit(:update)
        end

        it 'denies destroy access' do
          expect(subject).to_not permit(:destroy)
        end
      end
    end
  end

  context 'for user' do
    let(:context) { authorization_context(account:, bearer:, token:) }

    context 'without product license' do
      let(:bearer) { create(:user, account:) }
      let(:token)  { create(:token, account:, bearer:) }

      it 'denies index access' do
        expect(subject).to_not permit(:index)
      end

      it 'denies show access' do
        expect(subject).to_not permit(:show)
      end

      it 'denies create access' do
        expect(subject).to_not permit(:create)
      end

      it 'denies update access' do
        expect(subject).to_not permit(:update)
      end

      it 'denies destroy access' do
        expect(subject).to_not permit(:destroy)
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

      it 'denies update access' do
        expect(subject).to_not permit(:update)
      end

      it 'denies destroy access' do
        expect(subject).to_not permit(:destroy)
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

    it 'denies update access' do
      expect(subject).to_not permit(:update)
    end

    it 'denies destroy access' do
      expect(subject).to_not permit(:destroy)
    end
  end
end
