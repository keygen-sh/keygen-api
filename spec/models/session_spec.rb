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
