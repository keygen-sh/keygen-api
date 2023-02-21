# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Dirtyable, type: :concern do
  let(:account) { create(:account) }

  describe 'ActiveModel' do
    describe '.tracks_dirty_attributes_for' do
      let(:dirtyable) {
        Class.new {
          include ActiveModel::Model
          include ActiveModel::Attributes
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
