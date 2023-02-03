# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Dirtyable, type: :concern do
  let(:account) { create(:account) }

  describe 'ActiveModel' do
    describe '.tracks_dirty_attributes' do
      let(:dirtyable) {
        Class.new {
          include ActiveModel::Model
          include ActiveModel::Attributes
          include Dirtyable

          tracks_dirty_attributes

          attribute :foo, :integer
          attribute :bar, :integer
          attribute :baz, :integer
        }
      }

      it 'should track assigned attributes' do
        model = dirtyable.new
        model.assign_attributes(foo: 1)

        expect(model.foo_attribute_assigned?).to be true
        expect(model.bar_attribute_assigned?).to be false
        expect(model.baz_attribute_assigned?).to be false
      end

      it 'should raise for undefined method' do
        model = dirtyable.new

        expect { model.qux_attribute_assigned? }.to raise_error NoMethodError
      end
    end

    describe '.tracks_dirty_attributes_for' do
      let(:dirtyable) {
        Class.new {
          include ActiveModel::Model
          include Dirtyable

          tracks_dirty_attributes_for :foo
        }
      }

      it 'should raise' do
        expect { dirtyable }.to raise_error NotImplementedError
      end
    end
  end

  describe 'ActiveRecord' do
    # TODO(ezekg)
  end
end
