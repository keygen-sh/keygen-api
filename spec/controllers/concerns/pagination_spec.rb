# frozen_string_literal: true

require 'temporary_tables'
require 'rails_helper'
require 'spec_helper'

describe Pagination, type: :concern do
  temporary_table :paginated_records, id: :uuid do |t|
    t.timestamps
  end

  temporary_model :paginated_record do
    include Limitable, Orderable, Pageable

    scope :ordered, -> (order) { reorder(created_at: order, id: order) }
    scope :unordered, -> { reorder(nil) }
  end

  let(:model) { PaginatedRecord }

  def build_request(query_parameters: {}, path: '/v1/test')
    instance_double(ActionDispatch::Request, query_parameters:, path:)
  end

  describe Pagination::Params do
    it 'should parse cursor params' do
      params = Pagination::Params.new(page: { cursor: 'abc', size: 5 })

      expect(params.cursor).to eq 'abc'
      expect(params.size).to eq 5
      expect(params).to be_paginated
      expect(params).to be_cursor
      expect(params).not_to be_offset
    end

    it 'should parse an empty cursor' do
      params = Pagination::Params.new(page: { cursor: '', size: 3 })

      expect(params.cursor).to eq ''
      expect(params.size).to eq 3
      expect(params).to be_paginated
      expect(params).to be_cursor
    end

    it 'should parse offset params' do
      params = Pagination::Params.new(page: { number: 2, size: 5 })

      expect(params.number).to eq 2
      expect(params.size).to eq 5
      expect(params).to be_paginated
      expect(params).to be_offset
      expect(params).not_to be_cursor
    end

    it 'should parse string page values' do
      params = Pagination::Params.new(page: { number: '3', size: '15' })

      expect(params.number).to eq 3
      expect(params.size).to eq 15
    end

    it 'should not be paginated without page param' do
      params = Pagination::Params.new({})

      expect(params).not_to be_paginated
    end

    it 'should use default order' do
      params = Pagination::Params.new({})

      expect(params.order).to eq Pagination::DEFAULT_PAGE_ORDER
    end

    it 'should parse order' do
      params = Pagination::Params.new(order: :asc)

      expect(params.order).to eq :asc
      expect(params).not_to be_paginated
    end

    it 'should use default limit' do
      params = Pagination::Params.new({})

      expect(params.limit).to eq Pagination::DEFAULT_PAGE_SIZE
    end

    it 'should parse limit' do
      params = Pagination::Params.new(limit: 42)

      expect(params.limit).to eq 42
      expect(params).not_to be_paginated
    end

    it 'should use default size when page has no size' do
      params = Pagination::Params.new(page: {})

      expect(params.size).to eq Pagination::DEFAULT_PAGE_SIZE
    end

    it 'should raise for invalid page structure' do
      expect {
        Pagination::Params.new(page: { foo: 1 })
      }.to raise_error(Keygen::Error::InvalidParameterError, /page must be an object/)
    end

    it 'should parse cursor without size using default' do
      params = Pagination::Params.new(page: { cursor: 'abc' })

      expect(params.cursor).to eq 'abc'
      expect(params.size).to eq Pagination::DEFAULT_PAGE_SIZE
      expect(params).to be_paginated
      expect(params).to be_cursor
    end

    it 'should parse cursor without size using limit' do
      params = Pagination::Params.new(limit: 5, page: { cursor: 'abc' })

      expect(params.cursor).to eq 'abc'
      expect(params.size).to eq 5
      expect(params).to be_paginated
      expect(params).to be_cursor
    end

    it 'should parse number without size using default' do
      params = Pagination::Params.new(page: { number: 1 })

      expect(params.number).to eq 1
      expect(params.size).to eq Pagination::DEFAULT_PAGE_SIZE
      expect(params).to be_paginated
      expect(params).to be_offset
    end

    it 'should parse number without size using limit' do
      params = Pagination::Params.new(limit: 5, page: { number: 1 })

      expect(params.number).to eq 1
      expect(params.size).to eq 5
      expect(params).to be_paginated
      expect(params).to be_offset
    end

    it 'should raise for page without cursor or number' do
      expect {
        Pagination::Params.new(page: { size: 25 })
      }.to raise_error(Keygen::Error::InvalidParameterError, /page must be an object/)
    end
  end

  describe Pagination::Paginator do
    before do
      5.times { model.create!(created_at: it.minutes.ago) }
    end

    context 'with keyset params' do
      let(:request) { build_request(query_parameters: { page: { cursor: '', size: 3 } }) }

      it 'should return a keyset result' do
        result = Pagination::Paginator.new(model.all, request:).call

        expect(result).to be_a Pagination::KeysetResult
      end
    end

    context 'with offset params' do
      let(:request) { build_request(query_parameters: { page: { number: 1, size: 3 } }) }

      it 'should return an offset result' do
        result = Pagination::Paginator.new(model.all, request:).call

        expect(result).to be_a Pagination::OffsetResult
      end
    end

    context 'with limit params' do
      let(:request) { build_request(query_parameters: { limit: 5 }) }

      it 'should return a limit result' do
        result = Pagination::Paginator.new(model.all, request:).call

        expect(result).to be_a Pagination::LimitResult
      end
    end

    context 'with no params' do
      let(:request) { build_request(query_parameters: {}) }

      it 'should return a limit result' do
        result = Pagination::Paginator.new(model.all, request:).call

        expect(result).to be_a Pagination::LimitResult
      end
    end
  end

  describe Pagination::KeysetResult do
    before do
      5.times { model.create!(created_at: it.minutes.ago) }
    end

    let(:all_records) { model.reorder(created_at: :desc, id: :desc).to_a }

    context 'when more records exist' do
      let(:records) { model.with_keyset_pagination(size: 3, order: :desc) }
      let(:request) { build_request(query_parameters: { page: { cursor: '', size: 3 } }) }
      let(:result)  { Pagination::KeysetResult.new(records:, request:) }

      it 'should include a self link' do
        expect(result.links[:self]).to be_present
        expect(result.links[:self]).to include('page%5Bcursor%5D=')
        expect(result.links[:self]).to include('page%5Bsize%5D=3')
      end

      it 'should include a next link' do
        expect(result.links[:next]).to be_present
        expect(result.links[:next]).to include("page%5Bcursor%5D=#{records.next_cursor}")
        expect(result.links[:next]).to include('page%5Bsize%5D=3')
      end
    end

    context 'when no more records exist' do
      let(:records) { model.with_keyset_pagination(size: 5, order: :desc) }
      let(:request) { build_request(query_parameters: { page: { cursor: '', size: 5 } }) }
      let(:result)  { Pagination::KeysetResult.new(records:, request:) }

      it 'should include a self link' do
        expect(result.links[:self]).to be_present
      end

      it 'should not include a next link' do
        expect(result.links[:next]).to be_nil
      end
    end

    context 'with cursor on last page' do
      let(:cursor)  { all_records[2].id }
      let(:records) { model.with_keyset_pagination(cursor:, size: 3, order: :desc) }
      let(:request) { build_request(query_parameters: { page: { cursor:, size: 3 } }) }
      let(:result)  { Pagination::KeysetResult.new(records:, request:) }

      it 'should not include a next link' do
        expect(result.links[:next]).to be_nil
      end
    end

    it 'should strip token from links' do
      records = model.with_keyset_pagination(size: 3, order: :desc)
      request = build_request(query_parameters: { page: { cursor: '', size: 3 }, token: 'secret' })
      result  = Pagination::KeysetResult.new(records:, request:)

      expect(result.links[:self]).not_to include('token')
    end

    it 'should strip auth from links' do
      records = model.with_keyset_pagination(size: 3, order: :desc)
      request = build_request(query_parameters: { page: { cursor: '', size: 3 }, auth: 'secret' })
      result  = Pagination::KeysetResult.new(records:, request:)

      expect(result.links[:self]).not_to include('auth')
    end
  end

  describe Pagination::OffsetResult do
    before do
      5.times { model.create!(created_at: it.minutes.ago) }
    end

    context 'with count' do
      let(:records) { model.ordered(:desc).with_offset_pagination(number: 1, size: 2) }
      let(:request) { build_request(query_parameters: { page: { number: 1, size: 2 } }) }
      let(:result)  { Pagination::OffsetResult.new(records:, request:) }

      it 'should include a self link' do
        expect(result.links[:self]).to be_present
        expect(result.links[:self]).to include('page%5Bnumber%5D=1')
      end

      it 'should include a next link' do
        expect(result.links[:next]).to be_present
        expect(result.links[:next]).to include('page%5Bnumber%5D=2')
      end

      it 'should not include a prev link on first page' do
        expect(result.links[:prev]).to be_nil
      end

      it 'should include first and last links' do
        expect(result.links[:first]).to be_present
        expect(result.links[:first]).to include('page%5Bnumber%5D=1')
        expect(result.links[:last]).to be_present
        expect(result.links[:last]).to include('page%5Bnumber%5D=3')
      end

      it 'should include meta with count and pages' do
        expect(result.links[:meta]).to eq(pages: 3, count: 5)
      end

      context 'on a middle page' do
        let(:records) { model.ordered(:desc).with_offset_pagination(number: 2, size: 2) }
        let(:request) { build_request(query_parameters: { page: { number: 2, size: 2 } }) }
        let(:result)  { Pagination::OffsetResult.new(records:, request:) }

        it 'should include both prev and next links' do
          expect(result.links[:prev]).to be_present
          expect(result.links[:prev]).to include('page%5Bnumber%5D=1')
          expect(result.links[:next]).to be_present
          expect(result.links[:next]).to include('page%5Bnumber%5D=3')
        end
      end

      context 'on the last page' do
        let(:records) { model.ordered(:desc).with_offset_pagination(number: 3, size: 2) }
        let(:request) { build_request(query_parameters: { page: { number: 3, size: 2 } }) }
        let(:result)  { Pagination::OffsetResult.new(records:, request:) }

        it 'should not include a next link' do
          expect(result.links[:next]).to be_nil
        end

        it 'should include a prev link' do
          expect(result.links[:prev]).to be_present
          expect(result.links[:prev]).to include('page%5Bnumber%5D=2')
        end
      end
    end
  end

  describe Pagination::LimitResult do
    it 'should return empty links' do
      records = model.ordered(:desc).with_limit(10)
      request = build_request
      result  = Pagination::LimitResult.new(records:, request:)

      expect(result.links).to eq({})
    end
  end

  describe Pagination::Page do
    before do
      3.times { model.create!(created_at: it.minutes.ago) }
    end

    it 'should add pagination_links to a relation' do
      records = model.with_keyset_pagination(size: 3, order: :desc)
      request = build_request(query_parameters: { page: { cursor: '', size: 3 } })
      paged   = Pagination::KeysetResult.new(records:, request:)

      decorated = records.extending(Pagination::Page.new(paged:))

      expect(decorated).to respond_to(:pagination_links)
      expect(decorated.pagination_links).to eq paged.links
    end
  end

  describe '#apply_pagination' do
    let(:controller_class) {
      Class.new(ActionController::Base) {
        include Pagination
      }
    }

    let(:all_records) { model.reorder(created_at: :desc, id: :desc).to_a }

    before do
      5.times { model.create!(created_at: it.minutes.ago) }
    end

    context 'with keyset params' do
      let(:request) { build_request(query_parameters: { page: { cursor: '', size: 3 } }) }

      it 'should return the first page of records' do
        controller = controller_class.new
        allow(controller).to receive(:request).and_return(request)

        records = controller.send(:apply_pagination, model.all)

        expect(records.to_a).to eq all_records.first(3)
        expect(records.length).to eq 3
      end

      it 'should decorate the records with pagination_links' do
        controller = controller_class.new
        allow(controller).to receive(:request).and_return(request)

        records = controller.send(:apply_pagination, model.all)

        expect(records).to respond_to(:pagination_links)
        expect(records.pagination_links).to have_key(:self)
        expect(records.pagination_links).to have_key(:next)
      end
    end

    context 'with offset params' do
      let(:request) { build_request(query_parameters: { page: { number: 1, size: 2 } }) }

      it 'should return the first page of records' do
        controller = controller_class.new
        allow(controller).to receive(:request).and_return(request)

        records = controller.send(:apply_pagination, model.all)

        expect(records.to_a).to eq all_records.first(2)
        expect(records.length).to eq 2
      end

      it 'should decorate the records with pagination_links' do
        controller = controller_class.new
        allow(controller).to receive(:request).and_return(request)

        records = controller.send(:apply_pagination, model.all)

        expect(records).to respond_to(:pagination_links)
        expect(records.pagination_links).to have_key(:self)
        expect(records.pagination_links).to have_key(:next)
        expect(records.pagination_links).to have_key(:prev)
        expect(records.pagination_links).to have_key(:first)
        expect(records.pagination_links).to have_key(:last)
        expect(records.pagination_links).to have_key(:meta)
      end
    end

    context 'with limit params' do
      let(:request) { build_request(query_parameters: {}) }

      it 'should return records up to the default limit' do
        controller = controller_class.new
        allow(controller).to receive(:request).and_return(request)

        records = controller.send(:apply_pagination, model.all)

        expect(records.to_a).to eq all_records.first(Pagination::DEFAULT_PAGE_SIZE)
        expect(records.length).to eq 5
      end

      it 'should decorate the records with pagination_links' do
        controller = controller_class.new
        allow(controller).to receive(:request).and_return(request)

        records = controller.send(:apply_pagination, model.all)

        expect(records).to respond_to(:pagination_links)
        expect(records.pagination_links).to eq({})
      end
    end
  end
end
