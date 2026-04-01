# frozen_string_literal: true

require 'temporary_tables'
require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keyset_pagination'

describe KeysetPagination do
  before(:all) { KeysetPagination.configuration = nil } # FIXME(ezekg) override our initializer

  describe KeysetPagination::Configuration do
    around do |example|
      config_was, KeysetPagination.configuration = KeysetPagination.configuration, nil

      example.run
    ensure
      KeysetPagination.configuration = config_was
    end

    describe '#pagination_method_name' do
      it 'should default to :paginate' do
        expect(KeysetPagination.configuration.pagination_method_name).to eq :paginate
      end

      it 'should be configurable' do
        KeysetPagination.configure do |config|
          config.pagination_method_name = :keyset_paginate
        end

        expect(KeysetPagination.configuration.pagination_method_name).to eq :keyset_paginate
      end
    end

    describe '#pagination_param_name' do
      it 'should default to :page' do
        expect(KeysetPagination.configuration.pagination_param_name).to eq :page
      end

      it 'should be configurable' do
        KeysetPagination.configure do |config|
          config.pagination_param_name = :cursor
        end

        expect(KeysetPagination.configuration.pagination_param_name).to eq :cursor
      end
    end

    describe '#default_page_size' do
      it 'should default to 10' do
        expect(KeysetPagination.configuration.default_page_size).to eq 10
      end

      it 'should be configurable' do
        KeysetPagination.configure do |config|
          config.default_page_size = 25
        end

        expect(KeysetPagination.configuration.default_page_size).to eq 25
      end
    end

    describe '#max_page_size' do
      it 'should default to 100' do
        expect(KeysetPagination.configuration.max_page_size).to eq 100
      end

      it 'should be configurable' do
        KeysetPagination.configure do |config|
          config.max_page_size = 50
        end

        expect(KeysetPagination.configuration.max_page_size).to eq 50
      end
    end
  end

  describe KeysetPagination::Model do
    temporary_table :keyset_records do |t|
      t.timestamps
    end

    temporary_model :keyset_record do
      include KeysetPagination::Model

      keyset_pagination
    end

    let(:model) { KeysetRecord }

    describe '.keyset_pagination' do
      it 'should configure keyset pagination with default paginator' do
        expect(model.keyset_paginator).to eq KeysetPagination::DEFAULT_PAGINATOR
      end

      it 'should report keyset_pagination? as true' do
        expect(model.keyset_pagination?).to be true
      end

      context 'with default config' do
        temporary_table :default_keyset_records do |t|
          t.timestamps
        end

        temporary_model :default_keyset_record do
          include KeysetPagination::Model
        end

        it 'should have default paginator' do
          expect(DefaultKeysetRecord.keyset_paginator).to be_a Proc
          expect(DefaultKeysetRecord.keyset_paginator).to eq KeysetPagination::DEFAULT_PAGINATOR
        end
      end

      context 'with custom config' do
        temporary_table :custom_keyset_records do |t|
          t.timestamps
        end

        temporary_model :custom_keyset_record do
          include KeysetPagination::Model

          keyset_pagination do |scope, cursor:, size:, order:|
            scope.reorder(created_at: order).limit(size)
          end
        end

        it 'should have custom paginator' do
          expect(CustomKeysetRecord.keyset_paginator).to be_a Proc
          expect(CustomKeysetRecord.keyset_paginator).not_to eq KeysetPagination::DEFAULT_PAGINATOR
        end
      end

      context 'with empty config' do
        temporary_table :empty_keyset_records do |t|
          t.timestamps
        end

        temporary_model :empty_keyset_record do
          include KeysetPagination::Model

          keyset_pagination
        end

        it 'should have default paginator' do
          expect(EmptyKeysetRecord.keyset_paginator).to be_a Proc
          expect(EmptyKeysetRecord.keyset_paginator).to eq KeysetPagination::DEFAULT_PAGINATOR
        end
      end

      context 'without keyset pagination' do
        temporary_table :no_keyset_records do |t|
          t.timestamps
        end

        temporary_model :no_keyset_record

        it 'should not respond to keyset_pagination?' do
          expect(NoKeysetRecord.respond_to?(:keyset_pagination?)).to be false
        end
      end
    end

    describe '.paginate' do
      context 'with default paginator' do
        before do
          5.times { model.create!(created_at: it.minutes.ago) }
        end

        let(:all_records) { model.reorder(created_at: :desc, id: :desc) }

        it 'should return a relation' do
          result = model.paginate(size: 10)

          expect(result).to be_a ActiveRecord::Relation
        end

        it 'should return the first page when no cursor' do
          records = model.paginate(size: 3, order: :desc)

          expect(records).to eq all_records.first(3)
          expect(records.length).to eq 3
        end

        it 'should treat an empty cursor as no cursor' do
          records = model.paginate(cursor: '', size: 3, order: :desc)

          expect(records).to eq all_records.first(3)
          expect(records.length).to eq 3
        end

        it 'should return the next page using cursor' do
          first_page  = model.paginate(size: 3, order: :desc)
          next_cursor = first_page.last.id
          second_page = model.paginate(cursor: next_cursor, size: 3, order: :desc)

          expect(second_page).to eq all_records[3..4]
          expect(second_page.length).to eq 2 # only 2 left
        end

        it 'should paginate in ascending order' do
          asc_records = model.reorder(created_at: :asc, id: :asc)

          records = model.paginate(size: 3, order: :asc)

          expect(records).to eq asc_records.first(3)
          expect(records.length).to eq 3
        end

        it 'should return empty when no records match' do
          # get all 5 records
          all_records = model.paginate(size: 5, order: :desc)

          # get the next cursor
          next_cursor = all_records.last.id

          # should be an empty page
          records = model.paginate(cursor: next_cursor, size: 3, order: :desc)

          expect(records).to be_empty
        end

        it 'should use default page size from configuration' do
          records = model.paginate(order: :desc)

          # default page size is 10, we have 5 records
          expect(records.length).to eq 5
        end

        it 'should return exactly size records at boundary' do
          # request exactly the number of records available
          all_records = model.paginate(size: 5, order: :desc)

          expect(all_records.length).to eq 5
        end

        it 'should return exactly size records when more exist' do
          records = model.paginate(size: 4, order: :desc)

          expect(records.length).to eq 4
        end

        it 'should accept string order param' do
          records = model.paginate(size: 3, order: 'DESC')

          expect(records.first(3)).to eq all_records.first(3)
        end

        it 'should work with chained scopes' do
          record = all_records.first
          records = model.where(id: record.id).paginate(size: 10, order: :desc)

          expect(records).to eq [record]
        end

        it 'should expose current_cursor' do
          cursor = all_records.first.id
          result = model.paginate(cursor:, size: 3, order: :desc)

          expect(result.current_cursor).to eq cursor
        end

        it 'should expose current_cursor as nil for first page' do
          result = model.paginate(size: 3, order: :desc)

          expect(result.current_cursor).to be_nil
        end

        it 'should expose next_cursor' do
          result = model.paginate(size: 3, order: :desc)

          expect(result.next_cursor).to eq all_records[2].id
        end

        it 'should expose next_cursor as nil for empty results' do
          cursor = all_records.last.id
          result = model.paginate(cursor:, size: 3, order: :desc)

          expect(result.next_cursor).to be_nil
        end

        it 'should report has_more? when more records exist' do
          result = model.paginate(size: 3, order: :desc)

          expect(result.has_more?).to be true
        end

        it 'should report not has_more? on last page' do
          cursor = all_records[2].id
          result = model.paginate(cursor:, size: 3, order: :desc)

          expect(result.has_more?).to be false
        end

        it 'should report not has_more? on empty results' do
          cursor = all_records.last.id
          result = model.paginate(cursor:, size: 3, order: :desc)

          expect(result.has_more?).to be false
        end

        it 'should report not has_more? at exact boundary' do
          result = model.paginate(size: 5, order: :desc)

          expect(result.has_more?).to be false
        end
      end

      context 'with custom method name' do
        around do |example|
          config_was, KeysetPagination.configuration = KeysetPagination.configuration, nil

          KeysetPagination.configure do |config|
            config.pagination_method_name = :keyset_paginate
          end

          example.run
        ensure
          KeysetPagination.configuration = config_was
        end

        it 'should define scope with configured method name' do
          expect(KeysetRecord).to respond_to(:keyset_paginate)
        end

        it 'should not define scope with the default method name' do
          expect(KeysetRecord).not_to respond_to(:paginate)
        end
      end

      context 'with custom paginator' do
        temporary_table :custom_paginated_records do |t|
          t.string :category, null: false
          t.timestamps
        end

        temporary_model :custom_paginated_record do
          include KeysetPagination::Model

          keyset_pagination do |scope, cursor:, size:, order:|
            table = table_name

            if cursor.present?
              comparator = order == :desc ? '<' : '>'
              scope      = scope.where(
                "(#{table}.created_at, #{table}.category) #{comparator} (SELECT s.created_at, s.category FROM #{table} s WHERE s.id = ?)",
                cursor,
              )
            end

            scope.reorder("#{table}.created_at": order, "#{table}.category": order)
                 .limit(size)
          end
        end

        before do
          t = 3.minutes.ago

          CustomPaginatedRecord.create!(category: 'a', created_at: t)
          CustomPaginatedRecord.create!(category: 'b', created_at: t)
          CustomPaginatedRecord.create!(category: 'c', created_at: t + 1.minute)
        end

        it 'should paginate using the custom paginator' do
          records = CustomPaginatedRecord.paginate(size: 2, order: :desc)

          expect(records).to satisfy do
            it in [
              CustomPaginatedRecord(category: 'c'),
              CustomPaginatedRecord(category: 'b'),
            ]
          end
        end

        it 'should paginate to the next page with cursor' do
          first_page  = CustomPaginatedRecord.paginate(size: 2, order: :desc)
          next_cursor = first_page.last.id
          second_page = CustomPaginatedRecord.paginate(cursor: next_cursor, size: 2, order: :desc)

          expect(second_page).to satisfy do
            it in [CustomPaginatedRecord(category: 'a')]
          end
        end
      end

      context 'with size validation' do
        around do |example|
          config_was, KeysetPagination.configuration = KeysetPagination.configuration, nil

          KeysetPagination.configure do |config|
            config.default_page_size = 10
            config.max_page_size     = 50
          end

          example.run
        ensure
          KeysetPagination.configuration = config_was
        end

        it 'should raise error for size less than 1' do
          expect {
            model.paginate(size: 0, order: :desc)
          }.to raise_error(KeysetPagination::InvalidParameterError, /page size must be a number between 1 and 50/)
        end

        it 'should raise error for negative size' do
          expect {
            model.paginate(size: -1, order: :desc)
          }.to raise_error(KeysetPagination::InvalidParameterError, /page size must be a number between 1 and 50/)
        end

        it 'should raise error for size exceeding max' do
          expect {
            model.paginate(size: 51, order: :desc)
          }.to raise_error(KeysetPagination::InvalidParameterError, /page size must be a number between 1 and 50/)
        end

        it 'should accept size at max boundary' do
          result = model.paginate(size: 50, order: :desc)

          expect(result).to be_a ActiveRecord::Relation
        end

        it 'should accept size at min boundary' do
          result = model.paginate(size: 1, order: :desc)

          expect(result).to be_a ActiveRecord::Relation
        end

        it 'should coerce string size to integer' do
          result = model.paginate(size: '5', order: :desc)

          expect(result).to be_a ActiveRecord::Relation
        end

        it 'should set the parameter on the error' do
          expect {
            model.paginate(size: 0, order: :desc)
          }.to raise_error { |error|
            expect(error.parameter).to eq 'page[size]'
          }
        end
      end

      context 'with order validation' do
        it 'should raise error for invalid order' do
          expect {
            model.paginate(size: 10, order: :invalid)
          }.to raise_error(KeysetPagination::InvalidParameterError, /order is invalid/)
        end

        it 'should set the parameter on the error' do
          expect {
            model.paginate(size: 10, order: :invalid)
          }.to raise_error { |error|
            expect(error.parameter).to eq 'order'
          }
        end

        it 'should accept :asc' do
          result = model.paginate(size: 10, order: :asc)

          expect(result).to be_a ActiveRecord::Relation
        end

        it 'should accept :desc' do
          result = model.paginate(size: 10, order: :desc)

          expect(result).to be_a ActiveRecord::Relation
        end
      end
    end
  end
end
