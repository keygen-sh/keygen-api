# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'temporary_tables'

describe TemporaryTables do
  include TemporaryTables::Methods

  describe '.temporary_table' do
    temporary_table :tmp_records do |t|
      t.string :name
    end

    # FIXME(ezekg) is there a better way to test this?
    before :all do
      expect(ActiveRecord::Base.connection.table_exists?(:tmp_records)).to be_falsey
    end

    it 'creates a temporary table' do
      expect(ActiveRecord::Base.connection.table_exists?(:tmp_records)).to be_truthy
    end

    after :all do
      expect(ActiveRecord::Base.connection.table_exists?(:tmp_records)).to be_falsey
    end
  end

  describe '.temporary_model' do
    describe 'ActiveRecord' do
      temporary_table :tmp_records do |t|
        t.string :name
      end

      temporary_model :tmp_record

      before :all do
        expect('TmpRecord'.safe_constantize).to be nil
      end

      it 'creates a temporary active record' do
        expect(klass = 'TmpRecord'.safe_constantize).to_not be nil
        expect(klass.table_name).to eq 'tmp_records'
        expect(klass.name).to eq 'TmpRecord'
        expect(record = klass.create).to be_an ActiveRecord::Base
        expect(record.id).to be_an Integer
        expect(instance = klass.new(name: 'test')).to be_an ActiveRecord::Base
        expect(instance.name).to eq 'test'
      end

      after :all do
        expect('TmpRecord'.safe_constantize).to be nil
      end
    end

    describe 'ActiveModel' do
      temporary_model :tmp_model, table_name: nil, base_class: nil do
        include ActiveModel::Model, ActiveModel::Attributes, ActiveModel::API

        attribute :name, :string
      end

      before :all do
        expect('TmpModel'.safe_constantize).to be nil
      end

      it 'creates a temporary active model' do
        expect(klass = 'TmpModel'.safe_constantize).to_not be nil
        expect(klass.respond_to?(:table_name)).to be false
        expect(klass.name).to eq 'TmpModel'
        expect(instance = klass.new(name: 'test')).to be_an ActiveModel::Model
        expect(instance.name).to eq 'test'
      end

      after :all do
        expect('TmpModel'.safe_constantize).to be nil
      end
    end

    describe 'PORO' do
      temporary_model :tmp_model, table_name: nil, base_class: BasicObject do
        attr_accessor :name

        def initialize(name:) = @name = name

        def kind_of?(_) = true
      end

      before :all do
        expect('TmpModel'.safe_constantize).to be nil
      end

      it 'creates a temporary active model' do
        expect(klass = 'TmpModel'.safe_constantize).to_not be nil
        expect(klass.ancestors).to eq [TmpModel, BasicObject]
        expect(klass.respond_to?(:table_name)).to be false
        expect(klass.name).to eq 'TmpModel'
        expect(instance = klass.new(name: 'test')).to be_a BasicObject
        expect(instance.name).to eq 'test'
      end

      after :all do
        expect('TmpModel'.safe_constantize).to be nil
      end
    end

    describe 'context' do
      let(:test_variable) { :test_value }

      temporary_model :tmp_model, table_name: nil, base_class: nil do |context|
        define_singleton_method(:test_method) { context.test_variable }
      end

      it 'accesses the example context' do
        expect(TmpModel.test_method).to eq test_variable
      end
    end
  end
end
