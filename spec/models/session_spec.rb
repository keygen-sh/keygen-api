# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Session, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#bearer=' do
    context 'on build' do
      it 'should denormalize bearer from unpersisted token' do
        bearer  = build(:admin, account:)
        token   = build(:token, bearer:)
        session = build(:session, token:)

        expect(session.bearer_type).to eq bearer.class.name
        expect(session.bearer_id).to eq bearer.id
        expect(session.bearer).to eq bearer
      end

      it 'should denormalize bearer from persisted token' do
        bearer  = create(:admin, account:)
        token   = create(:token, bearer:)
        session = build(:session, token:)

        expect(session.bearer_type).to eq bearer.class.name
        expect(session.bearer_id).to eq bearer.id
        expect(session.bearer).to eq bearer
      end
    end

    context 'on create' do
      it 'should denormalize bearer from unpersisted token' do
        bearer  = build(:admin, account:)
        token   = build(:token, bearer:)
        session = create(:session, token:)

        expect(session.bearer_type).to eq bearer.class.name
        expect(session.bearer_id).to eq bearer.id
        expect(session.bearer).to eq bearer
      end

      it 'should denormalize bearer from persisted token' do
        bearer  = create(:admin, account:)
        token   = create(:token, bearer:)
        session = create(:session, token:)

        expect(session.bearer_type).to eq bearer.class.name
        expect(session.bearer_id).to eq bearer.id
        expect(session.bearer).to eq bearer
      end
    end

    context 'on update' do
      it 'should raise on token/bearer mismatch' do
        session = create(:session, account:)
        bearer  = create(:license, account:)
        token   = create(:token, bearer:)

        expect(session.bearer_type).to_not eq bearer.class.name
        expect(session.bearer_id).to_not eq bearer.id
        expect(session.bearer).to_not eq bearer

        expect { session.update!(token:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#parent=' do
    before { Sidekiq::Testing.inline! }
    after  { Sidekiq::Testing.fake! }

    it 'should allow a child session for a nil environment parent' do
      environment = create(:environment, :isolated, account:)
      parent      = create(:session, account:, environment: nil, token: nil)
      child       = build(:session, account:, environment:, bearer: parent.bearer, parent:, token: nil, expiry: parent.expiry)

      expect(child).to be_valid
    end

    it 'should allow a nested child session' do
      environment = create(:environment, :isolated, account:)
      parent      = create(:session, account:, environment: nil, token: nil)
      child       = create(:session, account:, environment:, bearer: parent.bearer, parent:, token: nil, expiry: parent.expiry)
      grandchild  = build(:session, account:, environment:, bearer: child.bearer, parent: child, token: nil, expiry: child.expiry)

      expect(grandchild).to be_valid
    end

    it 'should allow a parent from an environment' do
      environment = create(:environment, :isolated, account:)
      parent      = create(:session, account:, environment:)
      child       = build(:session, account:, environment:, bearer: parent.bearer, parent:, token: nil, expiry: parent.expiry)

      expect(child).to be_valid
    end

    it 'should destroy child sessions with their parent' do
      environment = create(:environment, :isolated, account:)
      parent      = create(:session, account:, environment: nil, token: nil)
      child       = create(:session, account:, environment:, bearer: parent.bearer, parent:, token: nil, expiry: parent.expiry)
      grandchild  = create(:session, account:, environment:, bearer: child.bearer, parent: child, token: nil, expiry: child.expiry)

      expect { parent.destroy }.to change(Session, :count).by(-3)
      expect(Session.exists?(child.id)).to be false
      expect(Session.exists?(grandchild.id)).to be false
    end

    it "should not allow a child session with a different bearer than its parent" do
      parent = create(:session, account:, environment: nil, token: nil)
      child  = build(:session, account:, bearer: create(:admin, account:), parent:, token: nil, expiry: parent.expiry)

      expect(child).to_not be_valid
      expect(child.errors[:bearer]).to include 'bearer must match parent bearer'
    end
  end

  describe '#expires_in?' do
    it 'should return true when expiring within duration' do
      session = create(:session, account:, expiry: 3.hours.from_now)

      expect(session.expires_in?(1.hour)).to be false
      expect(session.expires_in?(2.9.hours)).to be false
      expect(session.expires_in?(3.hours)).to be true
      expect(session.expires_in?(1.day)).to be true
    end
  end

  describe '#expired?' do
    it 'should return false when not expired' do
      session = create(:session, account:, expiry: 3.hours.from_now)

      expect(session.expired?).to be false
    end

    it 'should return true when expired' do
      session = create(:session, account:, expiry: 3.hours.ago)

      expect(session.expired?).to be true
    end
  end
end
