# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

# FIXME(ezekg) This could be a lot more modular, not having dependencies
#              on the :account and :environment associations, nor on the
#              :created_at and :id columns, but I can't be bothered.
shared_examples :dirtyable do
  let(:factory) { described_class.name.demodulize.underscore }
  let(:account) { create(:account) }

  describe '.tracks_attributes' do
    context 'when tracking some attributes' do
      let(:dirtyable) {
        Class.new(described_class) do
          tracks_attributes :account_id
        end
      }

      it 'should track attribute assignment' do
        model = dirtyable.new
        model.assign_attributes(account_id: SecureRandom.uuid)

        expect(model.account_id_attribute_assigned?).to be true
        expect { model.created_at_attribute_assigned? }.to raise_error NoMethodError
        expect { model.id_attribute_assigned? }.to raise_error NoMethodError
      end

      it 'should track init assignment' do
        model = dirtyable.new(account_id: SecureRandom.uuid)

        expect(model.account_id_attribute_assigned?).to be true
      end

      it 'should track nil assignment' do
        model = dirtyable.new
        model.assign_attributes(account_id: nil)

        expect(model.account_id_attribute_assigned?).to be true
      end
    end

    context 'when tracking all attributes' do
      let(:dirtyable) {
        Class.new(described_class) do
          tracks_attributes
        end
      }

      it 'should track attribute assignment' do
        model = dirtyable.new
        model.assign_attributes(account_id: SecureRandom.uuid, created_at: Time.current)

        expect(model.account_id_attribute_assigned?).to be true
        expect(model.created_at_attribute_assigned?).to be true
        expect(model.id_attribute_assigned?).to be false
        expect { model.foo_attribute_assigned? }.to raise_error NoMethodError
      end
    end

    context "when tracking attributes that don't exist" do
      let(:dirtyable) {
        Class.new(described_class) do
          tracks_attributes :foo
        end
      }

      it 'should raise' do
        expect { dirtyable }.to raise_error NotImplementedError
      end
    end
  end

  describe '.tracks_nested_attributes_for' do
    let(:dirtyable) {
      Class.new(described_class) do
        accepts_nested_attributes_for :account
        tracks_nested_attributes_for :account

        accepts_nested_attributes_for :environment
        tracks_nested_attributes_for :environment
      end
    }

    it 'should track nested attribute assignment' do
      model = dirtyable.new
      model.assign_attributes(account_attributes: { name: 'Test' })

      expect(model.account_attributes_assigned?).to be true
      expect(model.environment_attributes_assigned?).to be false
      expect { model.foo_attributes_assigned? }.to raise_error NoMethodError
    end

    it 'should track blank assignment' do
      model = dirtyable.new
      model.assign_attributes(account_attributes: {})

      expect(model.account_attributes_assigned?).to be true
    end

    it 'should track init assignment' do
      model = dirtyable.new(account_attributes: { name: 'Test' })

      expect(model.account_attributes_assigned?).to be true
    end
  end
end
