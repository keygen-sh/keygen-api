# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Denormalizable, type: :concern do
  let(:account)        { create(:account) }
  let(:denormalizable) {
    Class.new ActiveRecord::Base do
      def self.table_name = 'licenses'
      def self.name       = 'License'

      include Denormalizable

      belongs_to :policy
      has_many :machines
    end
  }

  describe '.denormalizes' do
    context 'when denormalizing :from' do
      it 'should not raise for valid :from association' do
        expect { denormalizable.denormalizes :product_id, from: :policy }.to_not raise_error
      end

      it 'should raise for invalid :from association' do
        expect { denormalizable.denormalizes :product_id, from: :foo }.to raise_error ArgumentError
      end

      it 'should not raise with true :prefix' do
        expect { denormalizable.denormalizes :product_id, from: :policy, prefix: true }.to_not raise_error
      end

      it 'should not raise with false :prefix' do
        expect { denormalizable.denormalizes :product_id, from: :policy, prefix: false }.to_not raise_error
      end

      it 'should not raise with symbol :prefix' do
        expect { denormalizable.denormalizes :product_id, from: :policy, prefix: :foo }.to_not raise_error
      end
    end

    context 'when denormalizing :to' do
      it 'should not raise for valid :to association' do
        expect { denormalizable.denormalizes :product_id, to: :machines }.to_not raise_error
      end

      it 'should raise for invalid :to association' do
        expect { denormalizable.denormalizes :product_id, to: :foo }.to raise_error ArgumentError
      end

      it 'should not raise with true :prefix' do
        expect { denormalizable.denormalizes :product_id, to: :machines, prefix: true }.to_not raise_error
      end

      it 'should not raise with false :prefix' do
        expect { denormalizable.denormalizes :product_id, to: :machines, prefix: false }.to_not raise_error
      end

      it 'should not raise with symbol :prefix' do
        expect { denormalizable.denormalizes :product_id, to: :machines, prefix: :foo }.to_not raise_error
      end
    end

    it 'should raise for :with' do
      expect { denormalizable.denormalizes :product_id, with: :foo }.to raise_error NotImplementedError
    end

    it 'should raise for missing args' do
      expect { denormalizable.denormalizes :product_id }.to raise_error ArgumentError
    end
  end
end
