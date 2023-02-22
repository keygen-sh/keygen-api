# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Dirtyable, type: :concern do
  let(:account) { create(:account) }

  describe 'ActiveModel' do
    describe '.tracks_attribute_assignments' do
      context 'when tracking some attributes' do
        let(:dirtyable) {
          Class.new {
            include ActiveModel::Model
            include ActiveModel::Attributes
            include Dirtyable

            attribute :foo, :integer
            attribute :bar, :integer
            attribute :baz, :integer
            tracks_attribute_assignments :foo
          }
        }

        it 'should track assigned attributes' do
          model = dirtyable.new
          model.assign_attributes(foo: 1, bar: 2)

          expect(model.foo_attribute_assigned?).to be true
          expect { model.bar_attribute_assigned? }.to raise_error NoMethodError
          expect { model.baz_attribute_assigned? }.to raise_error NoMethodError
        end
      end

      context 'when tracking all attributes' do
        let(:dirtyable) {
          Class.new {
            include ActiveModel::Model
            include ActiveModel::Attributes
            include Dirtyable

            attribute :foo, :integer
            attribute :bar, :integer
            attribute :baz, :integer

            tracks_attribute_assignments
          }
        }

        it 'should track assigned attributes' do
          model = dirtyable.new
          model.assign_attributes(foo: 1, bar: 2)

          expect(model.foo_attribute_assigned?).to be true
          expect(model.bar_attribute_assigned?).to be true
          expect(model.baz_attribute_assigned?).to be false
          expect { model.qux_attribute_assigned? }.to raise_error NoMethodError
        end
      end

      context "when tracking attributes that don't exist" do
        let(:dirtyable) {
          Class.new {
            include ActiveModel::Model
            include ActiveModel::Attributes
            include Dirtyable

            tracks_attribute_assignments :foo
          }
        }

        it 'should raise' do
          expect { dirtyable }.to raise_error NotImplementedError
        end
      end
    end

    describe '.tracks_attribute_assignments_for' do
      let(:dirtyable) {
        Class.new {
          include ActiveModel::Model
          include ActiveModel::Attributes
          include Dirtyable

          tracks_attribute_assignments_for :foo
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
